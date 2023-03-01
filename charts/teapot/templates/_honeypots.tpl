{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/honeypots/docker-compose.yml */}}
{{/* container spec and volumes for honeypots */}}
{{- define "honeypots.containers" }}
## Source: _honeypots.tpl
- image: dtagdevsec/honeypots:2204
  name: honeypots
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/honeypots
    name: data
    subPath: honeypots/log
  - mountPath: /tmp
    name: honeypots-tmp
{{- end }}
{{- define "honeypots.volumes" }}
## Source: _honeypots.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: honeypots-tmp
{{- end }}
{{- define "honeypots.extras" }}
## Source: _honeypots.tpl
{{- end }}
