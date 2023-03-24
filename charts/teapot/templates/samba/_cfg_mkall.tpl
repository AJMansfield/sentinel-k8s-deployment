{{- define "samba.internal.cfg_mkall" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-samba-mkall
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
data:
{{ (.Files.Glob "files/samba/mkall/*").AsConfig | indent 2 }}
{{- end }}