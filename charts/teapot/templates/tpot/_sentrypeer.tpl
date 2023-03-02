{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/sentrypeer/docker-compose.yml */}}
{{/* container spec and volumes for sentrypeer */}}
{{- define "sentrypeer.containers" }}
## Source: _sentrypeer.tpl
- env:
  - SENTRYPEER_VERBOSE=1
  - SENTRYPEER_DEBUG=1
  image: dtagdevsec/sentrypeer:2204
  name: sentrypeer
  volumeMounts:
  - mountPath: /var/log/sentrypeer
    name: data
    subPath: sentrypeer/log
{{- end }}
{{- define "sentrypeer.volumes" }}
## Source: _sentrypeer.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "sentrypeer.extras" }}
## Source: _sentrypeer.tpl
{{- end }}
