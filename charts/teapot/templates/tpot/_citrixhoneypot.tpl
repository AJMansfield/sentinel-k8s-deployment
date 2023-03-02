{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/citrixhoneypot/docker-compose.yml */}}
{{/* container spec and volumes for citrixhoneypot */}}
{{- define "citrixhoneypot.containers" }}
## Source: _citrixhoneypot.tpl
- image: dtagdevsec/citrixhoneypot:2204
  name: citrixhoneypot
  volumeMounts:
  - mountPath: /opt/citrixhoneypot/logs
    name: data
    subPath: citrixhoneypot/logs
{{- end }}
{{- define "citrixhoneypot.volumes" }}
## Source: _citrixhoneypot.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "citrixhoneypot.extras" }}
## Source: _citrixhoneypot.tpl
{{- end }}
