{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/medpot/docker-compose.yml */}}
{{/* container spec and volumes for medpot */}}
{{- define "medpot.containers" }}
## Source: _medpot.tpl
- image: dtagdevsec/medpot:2204
  name: medpot
  volumeMounts:
  - mountPath: /var/log/medpot
    name: data
    subPath: medpot/log/
{{- end }}
{{- define "medpot.volumes" }}
## Source: _medpot.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "medpot.extras" }}
## Source: _medpot.tpl
{{- end }}
