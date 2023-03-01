{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/dionaea/docker-compose.yml */}}
{{/* container spec and volumes for dionaea */}}
{{- define "dionaea.containers" }}
- image: dtagdevsec/dionaea:2204
  name: dionaea
  volumeMounts:
  - mountPath: /opt/dionaea/var/dionaea/roots/ftp
    name: data
    subPath: dionaea/roots/ftp
  - mountPath: /opt/dionaea/var/dionaea/roots/tftp
    name: data
    subPath: dionaea/roots/tftp
  - mountPath: /opt/dionaea/var/dionaea/roots/www
    name: data
    subPath: dionaea/roots/www
  - mountPath: /opt/dionaea/var/dionaea/roots/upnp
    name: data
    subPath: dionaea/roots/upnp
  - mountPath: /opt/dionaea/var/dionaea
    name: data
    subPath: dionaea
  - mountPath: /opt/dionaea/var/dionaea/binaries
    name: data
    subPath: dionaea/binaries
  - mountPath: /opt/dionaea/var/log
    name: data
    subPath: dionaea/log
  - mountPath: /opt/dionaea/var/dionaea/rtp
    name: data
    subPath: dionaea/rtp
{{- end }}
{{- define "dionaea.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "dionaea.extras" }}
{{- end }}
