{{- define "samba.internal.vol-shares" }}
## Source: samba/_vol-shares.tpl
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-samba-shares
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
{{- end }}