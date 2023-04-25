{{- define "samba.containers" }}
## Source: templates/_samba.tpl
- name: smb
  image: servercontainers/samba
  command: [ "runsvdir", "-P", "/container/config/runit" ]
  volumeMounts:
  - name: data
    mountPath: /shares
    subPath: samba/shares
  - name: data
    mountPath: /var/log/samba
    subPath: samba/log
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
  resources:
    requests:
      memory: 16Mi
      cpu: 1m
    limits:
      memory: 24Mi
      cpu: 2m
{{- end }}
{{- define "samba.volumes" }}
## Source: templates/_samba.tpl
- name: samba-config
  configMap:
    name: {{ .Release.Name }}-samba-samba
- name: samba-avahi
  configMap:
    name: {{ .Release.Name }}-samba-avahi
{{- end }}
{{- define "samba.extras" }}
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/auditbeat.yaml") . }}
---
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/cfg_avahi.yaml") . }}
---
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/cfg_mkall.yaml") . }}
---
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/cfg_samba.yaml") . }}
---
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/filebeat.yaml") . }}
---
## Source: templates/_samba.tpl
{{ tpl (.Files.Get "files/samba/extras/mkall.yaml") . }}
---
## Source: templates/_samba.tpl
{{/* tpl (.Files.Get "files/samba/extras/vol_logs.yaml") . */}}
---
## Source: templates/_samba.tpl
{{/* tpl (.Files.Get "files/samba/extras/vol_shares.yaml") . */}}
{{- end }}