{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/adbhoney/docker-compose.yml */}}
{{/* container spec and volumes for adbhoney */}}
{{- define "adbhoney.containers" }}
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
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "adbhoney.extras" }}
{{- end }}
