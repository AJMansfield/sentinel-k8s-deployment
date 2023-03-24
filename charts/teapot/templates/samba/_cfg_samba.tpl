{{- define "samba.internal.cfg_samba" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-samba-samba
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
data:
{{ tpl (.Files.Glob "files/samba/samba/*").AsConfig . | indent 2 }}
{{- end }}