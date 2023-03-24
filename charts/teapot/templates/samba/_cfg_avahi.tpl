{{- define "samba.sub.extras.cfg_avahi" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-samba-avahi
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
data:
{{ tpl (.Files.Glob "files/samba/avahi/*").AsConfig . | indent 2 }}
{{- end }}