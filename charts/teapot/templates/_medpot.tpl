{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/medpot/docker-compose.yml */}}
{{/* container spec and volumes for medpot */}}
{{- define "medpot.containers" }}
- image: dtagdevsec/medpot:2204
  name: medpot
  volumeMounts:
  - mountPath: /var/log/medpot
    name: data
    subPath: medpot/log/
{{- end }}
{{- define "medpot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "medpot.extras" }}
{{- end }}
