{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/hellpot/docker-compose.yml */}}
{{/* container spec and volumes for hellpot */}}
{{- define "hellpot.containers" }}
## Source: _hellpot.tpl
- image: dtagdevsec/hellpot:2204
  name: hellpot
  volumeMounts:
  - mountPath: /var/log/hellpot
    name: data
    subPath: hellpot/log
{{- end }}
{{- define "hellpot.volumes" }}
## Source: _hellpot.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "hellpot.extras" }}
## Source: _hellpot.tpl
{{- end }}
