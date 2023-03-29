#!/usr/bin/env python3

import os
import subprocess
import tempfile
import logging
import re
import argparse

import yaml
from slugify import slugify

from helmtag import HelmTag, EnableHelmTag

DEFAULT_REPO = "https://github.com/telekom-security/tpotce.git"
DEFAULT_BRANCH = "master"
DEFAULT_PATH = "docker"
DEFAULT_EXCLUDE = ['p0f', 'fatt', 'suricata', 'elk', 'ewsposter', 'nginx', 'spiderfoot', 'deprecated']

DEFAULT_REL_BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DEFAULT_DEST = os.path.abspath(os.path.join(os.path.dirname(__file__), '../templates/tpot'))
DEFAULT_MOUNT = ['data']

def lerp(x0, x1, /, t):
    return x0*(1-t) + x1*t

def ensure_dir(path):
    try:
        os.makedirs(path)
        logging.info(f"made dirs up to {path}")
    except FileExistsError:
        logging.info(f"using existing {path}")

def get_compose_file(dir):
    for file in os.scandir(dir):
        if file.is_file() and re.match("docker-compose\.ya?ml", file.name):
            logging.info(f"found {file.path}")
            return file
    else:
        return None

def convert_service(name: str, service: dict,
                    pvc_name_template: str = "{{{{ .Release.Name }}}}-{name}",
                    ignore_volumes: list[str] = None):
    if ignore_volumes is None: ignore_volumes = []
    container = {}
    volumes = {}
    extras = []

    container['name'] = name
    container['image'] = service['image']
    container['volumeMounts'] = [{
        'name': 'resolv',
        'subPath': 'resolv.conf',
        'mountPath': '/etc/resolv.conf',
    }]
    if 'environment' in service:
        container['env'] = service['environment']
    
    for vol_mount in service.get('volumes', []):
        # example: vol_mount = '/data/honeypots/log:/var/log/honeypots'
        
        host_path, guest_path = vol_mount.split(":")
        pvc_name, pvc_path = host_path.removeprefix("/").split("/", 1)
        pvc_name = slugify(pvc_name)
        vol_name = pvc_name
        
        if vol_name not in ignore_volumes:
            volumes[vol_name] = {
                'name': vol_name,
                'persistentVolumeClaim': {
                    'claimName': HelmTag(pvc_name_template.format(name=pvc_name)),
                }}
        
        container['volumeMounts'].append({
            'name': vol_name,
            'subPath': pvc_path,
            'mountPath': guest_path,
            })
        
        if vol_name not in ignore_volumes:
            extras.append({
                'apiVersion': "v1",
                'kind': "PersistentVolumeClaim",
                'metadata': {
                    'name': HelmTag(pvc_name_template.format(name=pvc_name)),
                    'namespace': HelmTag('{{ .Release.Namespace }}'),
                    'labels': HelmTag('{{- include "teapot.potLabels" . | nindent 4 }}'),
                },
                'spec': {
                    'accessModes': ['ReadWriteOnce'],
                    'resources': {
                        'requests': {
                            'storage': '100Mi'
                        }
                    }
                }
            })
    
    for tmpfs_mount in service.get('tmpfs', []):
        # example: tmpfs_mount = '/tmp/conpot:uid=2000,gid=2000'
        
        guest_path, attrs = tmpfs_mount.split(":")
        attrs = dict(map(lambda a: a.split("="), attrs.split(",")))
        vol_name = slugify(name + '-' + guest_path.removeprefix("/"))

        securityContext = {}
        if 'uid' in attrs:
            securityContext['runAsUser'] = int(attrs['uid'])
        if 'gid' in attrs:
            securityContext['runAsGroup'] = int(attrs['gid'])
            # securityContext['fsGroup'] = int(attrs['gid'])
        if securityContext:
            container['securityContext'] = securityContext
        
        volumes[vol_name] = {
            'name': vol_name,
            'emptyDir': {
                'medium': 'Memory',
            }}
    
    return container, volumes, extras
 
def main():
    parser = argparse.ArgumentParser(description="Generate templates from tpot configurations.")
    parser.add_argument('-r', '--repo', default=DEFAULT_REPO, type=str, help="Git repository URL to clone from.")
    parser.add_argument('-b', '--branch', default=DEFAULT_BRANCH, type=str, help="Git branch to clone.")
    parser.add_argument('-p', '--path', default=DEFAULT_PATH, type=str, help="Source path within git repo to search for services.")
    parser.add_argument('-d', '--dest', default=DEFAULT_DEST, type=str, help="Destination directory to write templates to.")
    parser.add_argument('-x', '--exclude', default=[], action='extend', nargs='+', type=str, help="Don't generate based on these directories in the git repo; can specify multiple times.")
    parser.add_argument('-m', '--mount', default=[], action='extend', nargs='+', type=str, help="Don't create PVCs for these mounts; can specify multiple times.")
    parser.add_argument('--dryrun', action='store_true')

    parser.add_argument('-v', '--verbose', action='count', default=0)

    args = parser.parse_args()

    logging.basicConfig(level=max(lerp(logging.WARN, logging.INFO, args.verbose), logging.DEBUG))
    logging.debug(f'{args}')

    if args.exclude:
        exclude = parser.exclude
    else:
        exclude = DEFAULT_EXCLUDE
        logging.info(f"defaulting {exclude=}")
    
    if args.mount:
        mount = parser.mount
    else:
        mount = DEFAULT_MOUNT
        logging.info(f"defaulting {mount=}")
    
    out_dir = args.dest
    if not args.dryrun:
        ensure_dir(out_dir)
    out_rel_base = os.path.commonpath([DEFAULT_REL_BASE, os.path.abspath(out_dir)])

    gitignore_file = os.path.join(out_dir, ".gitignore")

    src_repo = args.repo
    src_branch = args.branch
    repo_url_guess = src_repo.removesuffix(".git") + "/tree/" + src_branch
    repo_name_guess = src_repo.removesuffix(".git").removesuffix("/").split("/")[-1]

    logging.debug(f"truncating {gitignore_file}")
    if not args.dryrun:
        with open(gitignore_file, 'w') as stream:
            pass # truncate file to zero length

    with tempfile.TemporaryDirectory(prefix=repo_name_guess + "-") as temp_dir:
        logging.info(f"cloning {src_repo}:{src_branch} into {temp_dir}")
        subprocess.run(["git", "clone", "-b", src_branch, "--depth", "1", src_repo, temp_dir])

        search_dir = os.path.join(temp_dir, args.path)
        
        for container_dir in os.scandir(search_dir):
            if not container_dir.is_dir() or container_dir.name in exclude:
                logging.info(f"skipping {container_dir.path}")
                continue
            logging.info(f"scanning {container_dir.path}")

            compose_file = get_compose_file(container_dir)
            out_fname = "_" + container_dir.name + ".tpl"
            out_file = os.path.join(out_dir, out_fname)
            out_rel = os.path.relpath(out_file, out_rel_base)

            logging.debug(f"writing {out_file}")
            if not args.dryrun:
                with open(out_file, 'w') as stream: # insert source citation
                    stream.write('{{/* derived from ' + repo_url_guess + '/' + os.path.relpath(compose_file, temp_dir) + ' */}}\n')
            
            logging.debug(f"appending {gitignore_file}")
            if not args.dryrun:
                with open(gitignore_file, 'a') as stream: # add generated files to .gitignore
                    stream.writelines([out_fname, "\n"])

            logging.debug(f"reading {compose_file.path}")
            with open(compose_file, 'r') as stream:
                contents = yaml.safe_load(stream)
            
            services = contents.get('services',{})

            for service_name, service in services.items():
                service_name = slugify(service_name)
                container, volumes, extras = convert_service(service_name, service, ignore_volumes=mount)

                logging.debug(f"appending {out_file}")
                if not args.dryrun:
                    with open(out_file, 'a') as stream:
                        stream.writelines([
                            '{{/* container spec and volumes for ' + service_name + ' */}}\n',
                            '{{- define "' + service_name + '.containers" }}\n',
                            f'## Source: {out_rel}\n',
                        ])
                        with EnableHelmTag():
                            yaml.dump([container], stream)
                        stream.writelines([
                            '{{- end }}\n',
                            '{{- define "' + service_name + '.volumes" }}\n',
                            f'## Source: {out_rel}\n',
                        ])
                        if volumes:
                            with EnableHelmTag():
                                yaml.dump(list(volumes.values()), stream)
                        stream.writelines([
                            '{{- end }}\n',
                            '{{- define "' + service_name + '.extras" }}\n',
                            f'## Source: {out_rel}\n',
                        ])
                        with EnableHelmTag():
                            yaml.dump_all(extras, stream)
                        stream.writelines([
                            '{{- end }}\n',
                        ])
if __name__ == "__main__":
    main()

        


    


        

