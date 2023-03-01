{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/endlessh/docker-compose.yml */}}
{{/* container spec and volumes for endlessh */}}
{{- define "endlessh.containers" }}
## Source: _endlessh.tpl
- image: dtagdevsec/endlessh:2204
  name: endlessh
  volumeMounts:
  - mountPath: /var/log/endlessh
    name: data
    subPath: endlessh/log
{{- end }}
{{- define "endlessh.volumes" }}
## Source: _endlessh.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "endlessh.extras" }}
## Source: _endlessh.tpl
{{- end }}
