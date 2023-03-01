{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/dicompot/docker-compose.yml */}}
{{/* container spec and volumes for dicompot */}}
{{- define "dicompot.containers" }}
- image: dtagdevsec/dicompot:2204
  name: dicompot
  volumeMounts:
  - mountPath: /var/log/dicompot
    name: data
    subPath: dicompot/log
{{- end }}
{{- define "dicompot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "dicompot.extras" }}
{{- end }}
