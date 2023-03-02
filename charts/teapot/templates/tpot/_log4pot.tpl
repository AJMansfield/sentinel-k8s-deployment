{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/log4pot/docker-compose.yml */}}
{{/* container spec and volumes for log4pot */}}
{{- define "log4pot.containers" }}
## Source: _log4pot.tpl
- image: dtagdevsec/log4pot:2204
  name: log4pot
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/log4pot/log
    name: data
    subPath: log4pot/log
  - mountPath: /var/log/log4pot/payloads
    name: data
    subPath: log4pot/payloads
  - mountPath: /tmp
    name: log4pot-tmp
{{- end }}
{{- define "log4pot.volumes" }}
## Source: _log4pot.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: log4pot-tmp
{{- end }}
{{- define "log4pot.extras" }}
## Source: _log4pot.tpl
{{- end }}
