{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/ipphoney/docker-compose.yml */}}
{{/* container spec and volumes for ipphoney */}}
{{- define "ipphoney.containers" }}
## Source: _ipphoney.tpl
- image: dtagdevsec/ipphoney:2204
  name: ipphoney
  volumeMounts:
  - mountPath: /opt/ipphoney/log
    name: data
    subPath: ipphoney/log
{{- end }}
{{- define "ipphoney.volumes" }}
## Source: _ipphoney.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "ipphoney.extras" }}
## Source: _ipphoney.tpl
{{- end }}
