{{- define "samba.containers" }}
## Source: samba/_samba.tpl
- name: smb
  image: servercontainers/samba
  command: [ "runsvdir", "-P", "/container/config/runit" ]
  volumeMounts:
  - name: samba-shares
    mountPath: /shares
  - name: samba-logs
    mountPath: /var/log
  - name: samba-config
    mountPath: /etc/samba
  - name: samba-avahi
    mountPath: /etc/avahi/services
  - name: resolv
    mountPath: /etc/resolv.conf
    subPath: resolv.conf
  securityContext:
    allowPrivilegeEscalation: true
    capabilities:
      add: ["NET_BIND_SERVICE", "NET_BROADCAST", "NET_ADMIN"]
{{- end }}
{{- define "samba.volumes" }}
## Source: samba/_samba.tpl
- name: samba-shares
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-samba-shares
- name: samba-logs
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-samba-logs
- name: samba-config
  configMap:
    name: {{ .Release.Name }}-samba-samba
- name: samba-avahi
  configMap:
    name: {{ .Release.Name }}-samba-avahi
{{- end }}