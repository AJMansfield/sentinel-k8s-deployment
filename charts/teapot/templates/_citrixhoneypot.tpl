{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/citrixhoneypot/docker-compose.yml */}}
{{/* container spec and volumes for citrixhoneypot */}}
{{- define "citrixhoneypot.containers" }}
- image: dtagdevsec/citrixhoneypot:2204
  name: citrixhoneypot
  volumeMounts:
  - mountPath: /opt/citrixhoneypot/logs
    name: data
    subPath: citrixhoneypot/logs
{{- end }}
{{- define "citrixhoneypot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "citrixhoneypot.extras" }}
{{- end }}
