{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/elasticpot/docker-compose.yml */}}
{{/* container spec and volumes for elasticpot */}}
{{- define "elasticpot.containers" }}
- image: dtagdevsec/elasticpot:2204
  name: elasticpot
  volumeMounts:
  - mountPath: /opt/elasticpot/log
    name: data
    subPath: elasticpot/log
{{- end }}
{{- define "elasticpot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "elasticpot.extras" }}
{{- end }}
