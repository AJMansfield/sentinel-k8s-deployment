{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/endlessh/docker-compose.yml */}}
{{/* container spec and volumes for endlessh */}}
{{- define "endlessh.containers" }}
- image: dtagdevsec/endlessh:2204
  name: endlessh
  volumeMounts:
  - mountPath: /var/log/endlessh
    name: data
    subPath: endlessh/log
{{- end }}
{{- define "endlessh.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "endlessh.extras" }}
{{- end }}
