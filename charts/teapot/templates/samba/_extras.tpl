{{- define "samba.extras" }}
## Source: samba/_extras.tpl
{{ .Files.Get "templates/samba/_mkall.yaml" }}
---
{{ .Files.Get "templates/samba/_filebeat.yaml" }}
---
{{ .Files.Get "templates/samba/_auditbeat.yaml" }}
---
{{ .Files.Get "templates/samba/_cfg_avahi.yaml" }}
---
{{ .Files.Get "templates/samba/_cfg_mkall.yaml" }}
---
{{ .Files.Get "templates/samba/_cfg_samba.yaml" }}
---
{{ .Files.Get "templates/samba/_vol_logs.yaml" }}
---
{{ .Files.Get "templates/samba/_vol_shares.yaml" }}
{{- end }}