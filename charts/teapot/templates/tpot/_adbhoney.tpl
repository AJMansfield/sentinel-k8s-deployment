{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/adbhoney/docker-compose.yml */}}
{{/* container spec and volumes for adbhoney */}}
{{- define "adbhoney.containers" }}
## Source: _adbhoney.tpl
- image: dtagdevsec/adbhoney:2204
  name: adbhoney
  volumeMounts:
  - mountPath: /opt/adbhoney/log
    name: data
    subPath: adbhoney/log
  - mountPath: /opt/adbhoney/dl
    name: data
    subPath: adbhoney/downloads
{{- end }}
{{- define "adbhoney.volumes" }}
## Source: _adbhoney.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "adbhoney.extras" }}
## Source: _adbhoney.tpl
{{- end }}
