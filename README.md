# sentinel-k8s-deployment

How to install:

1. Set up an instance of Ubuntu 22.04.2 LTS
2. Set up a storage volume for longhorn:
```bash
lvcreate --name longhorn-lv --size 100G ubuntu-vg
mkdir -p /var/lib/longhorn
cat >>/etc/fstab <<EOF
/dev/ubuntu-vg/longhorn-lv /var/lib/longhorn ext4 defaults 0 1
EOF
mount -a
```
3. Run `./install.sh -h <my-hostname> -p <my-bootstrap-password>`
4. Wait for the system to come up and show a webpage at `https://<my-hostname>/dashboard/`
5. While waiting, edit the yaml files in the `./values` folder. Ensure you set the hostname in `./values/elastic.yaml` and specify the SMTP account/connection parameters in `./values/virusalert-secret.yaml`, other values to taste.
6. Run `./populate.sh elastic install`
7. Run `./populate.sh virusalert install`
8. Run `./populate.sh honeypot install <num>` for each honeypot config you want to run corresponding to the numbered `./values/honeypot-<num>.yaml` files.
