{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/hellpot/docker-compose.yml */}}
{{/* container spec and volumes for hellpot */}}
{{- define "hellpot.containers" }}
- image: dtagdevsec/hellpot:2204
  name: hellpot
  volumeMounts:
  - mountPath: /var/log/hellpot
    name: data
    subPath: hellpot/log
{{- end }}
{{- define "hellpot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "hellpot.extras" }}
{{- end }}
