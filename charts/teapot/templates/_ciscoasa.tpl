{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/ciscoasa/docker-compose.yml */}}
{{/* container spec and volumes for ciscoasa */}}
{{- define "ciscoasa.containers" }}
- image: dtagdevsec/ciscoasa:2204
  name: ciscoasa
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/ciscoasa
    name: data
    subPath: ciscoasa/log
  - mountPath: /tmp/ciscoasa
    name: ciscoasa-tmp-ciscoasa
{{- end }}
{{- define "ciscoasa.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: ciscoasa-tmp-ciscoasa
{{- end }}
{{- define "ciscoasa.extras" }}
{{- end }}
