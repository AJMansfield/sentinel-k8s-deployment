{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/heralding/docker-compose.yml */}}
{{/* container spec and volumes for heralding */}}
{{- define "heralding.containers" }}
## Source: _heralding.tpl
- image: dtagdevsec/heralding:2204
  name: heralding
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/heralding
    name: data
    subPath: heralding/log
  - mountPath: /tmp/heralding
    name: heralding-tmp-heralding
{{- end }}
{{- define "heralding.volumes" }}
## Source: _heralding.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: heralding-tmp-heralding
{{- end }}
{{- define "heralding.extras" }}
## Source: _heralding.tpl
{{- end }}
