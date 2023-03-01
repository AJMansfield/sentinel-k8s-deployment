{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/honeytrap/docker-compose.yml */}}
{{/* container spec and volumes for honeytrap */}}
{{- define "honeytrap.containers" }}
- image: dtagdevsec/honeytrap:2204
  name: honeytrap
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /opt/honeytrap/var/attacks
    name: data
    subPath: honeytrap/attacks
  - mountPath: /opt/honeytrap/var/downloads
    name: data
    subPath: honeytrap/downloads
  - mountPath: /opt/honeytrap/var/log
    name: data
    subPath: honeytrap/log
  - mountPath: /tmp/honeytrap
    name: honeytrap-tmp-honeytrap
{{- end }}
{{- define "honeytrap.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: honeytrap-tmp-honeytrap
{{- end }}
{{- define "honeytrap.extras" }}
{{- end }}
