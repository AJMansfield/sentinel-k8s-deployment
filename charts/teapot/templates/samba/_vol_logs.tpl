{{- define "samba.internal.vol-logs" }}
## Source: samba/_vol-logs.tpl
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-samba-logs
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.logLabels" . | nindent 4 }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
{{- end }}