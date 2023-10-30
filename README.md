# sentinel-k8s-deployment

How to install:

1. Set up Ubuntu 22.04.2 LTS on all of the nodes you intend to use. Setting up SSH access is recommended.
2. Set up each node with storage volumes for longhorn and containerd (this can also be done during the initial installation of ubuntu).
```bash
lvresize --size 20G --resizefs /dev/ubuntu-vg/ubuntu-lv

lvcreate --name longhorn-lv --size 100G ubuntu-vg
mkfs.ext4 /dev/ubuntu-vg/longhorn-lv
mkdir --parents /var/lib/longhorn
cat >>/etc/fstab <<EOF
/dev/ubuntu-vg/longhorn-lv /var/lib/longhorn ext4 defaults 0 1
EOF

lvcreate --name containerd-lv --size 100G ubuntu-vg
mkfs.ext4 /dev/ubuntu-vg/containerd-lv
mkdir --parents /var/lib/rancher/rke2/agent/containerd
cat >>/etc/fstab <<EOF
/dev/ubuntu-vg/containerd-lv /var/lib/rancher/rke2/agent/containerd ext4 defaults 0 1
EOF

mount -a
```
3. Acquire this repository, by cloning from git or downloading, onto each of the nodes.
4. On the first node only: Run `sentinel/install.sh`. Most installs won't need to set any options, but a list of options and usage info is available with `--help` if desired.
5. For other nodes, run `sentinel/install-agent.sh`. Most installs won't need to set any options, but a list of options and usage info is available with `--help` if desired.
6. When prompted by the agent install script, copy the section labeled `Agent Config` from the output of the first node's install script and paste it into the prompt. (Alternatively, both scripts have a `-a` option that can be used to specify a file.)
7. While waiting for the install scripts to complete on all of the machines, create a copy of the `sentinel/values` folder from just your main machine, to be modified with the specifics of your own configuration.
    Ensure that you set the correct hostname in `values/elastic.yaml`, and that you specify the SMTP account/connection parameters in `values/virusalert-secret.yaml`. Other values to taste.
8. Once the main sentinel install script completes, navigate to the provided URL and use the bootstrap password to log in. Verify that all of the nodes of your cluster are visible in the rancher control panel.
9. After all previous steps are complete, run the populate scripts to install the core sentinel services:
    ```bash
    sentinel/populate.sh elastic install
    sentinel/populate.sh virusalert install
    sentinel/populate.sh lad install
    ```
10. For each honeypot configuration you wish to install (corresponding to the numbered `values/honeypot-<num>.yaml` config files), run `sentinel/populate.sh honeypot install <num>`.



### Extra Notes:

Script to change `/etc/fstab` to use LVM volume names instead of UUIDs
```bash
perl -0777pe 's!^# (.*) was on (/dev/.*-vg/.*-lv) during curtin installation\n^(/dev/disk/by-id/.*) \1 (.*)$!# $1 was on $3 during curtin installation\n$2 $1 $4!gm' < /etc/fstab
```