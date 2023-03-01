{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/ddospot/docker-compose.yml */}}
{{/* container spec and volumes for ddospot */}}
{{- define "ddospot.containers" }}
- image: dtagdevsec/ddospot:2204
  name: ddospot
  volumeMounts:
  - mountPath: /opt/ddospot/ddospot/logs
    name: data
    subPath: ddospot/log
  - mountPath: /opt/ddospot/ddospot/bl
    name: data
    subPath: ddospot/bl
  - mountPath: /opt/ddospot/ddospot/db
    name: data
    subPath: ddospot/db
{{- end }}
{{- define "ddospot.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "ddospot.extras" }}
{{- end }}
