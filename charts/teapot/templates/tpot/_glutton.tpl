{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/glutton/docker-compose.yml */}}
{{/* container spec and volumes for glutton */}}
{{- define "glutton.containers" }}
## Source: _glutton.tpl
- image: dtagdevsec/glutton:2204
  name: glutton
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/glutton
    name: data
    subPath: glutton/log
  - mountPath: /opt/glutton/rules/rules.yaml
    name: root
    subPath: tpotce/docker/glutton/dist/rules.yaml
  - mountPath: /var/lib/glutton
    name: glutton-var-lib-glutton
  - mountPath: /run
    name: glutton-run
{{- end }}
{{- define "glutton.volumes" }}
## Source: _glutton.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- name: root
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-root'
- emptyDir:
    medium: Memory
  name: glutton-var-lib-glutton
- emptyDir:
    medium: Memory
  name: glutton-run
{{- end }}
{{- define "glutton.extras" }}
## Source: _glutton.tpl
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: '{{ .Release.Namespace }}'
  name: '{{ .Release.Name }}-root'
  namespace: '{{ .Release.Namespace }}'
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
{{- end }}
