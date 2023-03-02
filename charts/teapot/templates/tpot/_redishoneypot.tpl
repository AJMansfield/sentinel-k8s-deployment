{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/redishoneypot/docker-compose.yml */}}
{{/* container spec and volumes for redishoneypot */}}
{{- define "redishoneypot.containers" }}
## Source: _redishoneypot.tpl
- image: dtagdevsec/redishoneypot:2204
  name: redishoneypot
  volumeMounts:
  - mountPath: /var/log/redishoneypot
    name: data
    subPath: redishoneypot/log
{{- end }}
{{- define "redishoneypot.volumes" }}
## Source: _redishoneypot.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "redishoneypot.extras" }}
## Source: _redishoneypot.tpl
{{- end }}
