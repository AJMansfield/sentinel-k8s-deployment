{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/mailoney/docker-compose.yml */}}
{{/* container spec and volumes for mailoney */}}
{{- define "mailoney.containers" }}
## Source: _mailoney.tpl
- env:
  - HPFEEDS_SERVER=
  - HPFEEDS_IDENT=user
  - HPFEEDS_SECRET=pass
  - HPFEEDS_PORT=20000
  - HPFEEDS_CHANNELPREFIX=prefix
  image: dtagdevsec/mailoney:2204
  name: mailoney
  volumeMounts:
  - mountPath: /opt/mailoney/logs
    name: data
    subPath: mailoney/log
{{- end }}
{{- define "mailoney.volumes" }}
## Source: _mailoney.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "mailoney.extras" }}
## Source: _mailoney.tpl
{{- end }}
