{{- define "samba.containers" }}
## Source: samba/_main.tpl
{{- include samba.sub.containers.samba . }}
{{- end }}
{{- define "samba.volumes" }}
## Source: samba/_main.tpl
{{- include samba.sub.volumes.samba . }}
{{- end }}
{{- define "samba.extras" }}
## Source: samba/_main.tpl
{{- include samba.sub.extras.filebeat . }}
---
{{- include samba.sub.extras.auditbeat . }}
---
{{- include samba.sub.extras.cfg_avahi . }}
---
{{- include samba.sub.extras.cfg_mkall . }}
---
{{- include samba.sub.extras.cfg_samba . }}
---
{{- include samba.sub.extras.vol_logs . }}
---
{{- include samba.sub.extras.vol_shares . }}
{{- end }}