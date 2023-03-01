{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/cowrie/docker-compose.yml */}}
{{/* container spec and volumes for cowrie */}}
{{- define "cowrie.containers" }}
- image: dtagdevsec/cowrie:2204
  name: cowrie
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /home/cowrie/cowrie/dl
    name: data
    subPath: cowrie/downloads
  - mountPath: /home/cowrie/cowrie/etc
    name: data
    subPath: cowrie/keys
  - mountPath: /home/cowrie/cowrie/log
    name: data
    subPath: cowrie/log
  - mountPath: /home/cowrie/cowrie/log/tty
    name: data
    subPath: cowrie/log/tty
  - mountPath: /tmp/cowrie
    name: cowrie-tmp-cowrie
  - mountPath: /tmp/cowrie/data
    name: cowrie-tmp-cowrie-data
{{- end }}
{{- define "cowrie.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: cowrie-tmp-cowrie
- emptyDir:
    medium: Memory
  name: cowrie-tmp-cowrie-data
{{- end }}
{{- define "cowrie.extras" }}
{{- end }}
