{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/redishoneypot/docker-compose.yml */}}
{{/* container spec and volumes for redishoneypot */}}
{{- define "redishoneypot.containers" }}
- image: dtagdevsec/redishoneypot:2204
  name: redishoneypot
  volumeMounts:
  - mountPath: /var/log/redishoneypot
    name: data
    subPath: redishoneypot/log
{{- end }}
{{- define "redishoneypot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "redishoneypot.extras" }}
{{- end }}
