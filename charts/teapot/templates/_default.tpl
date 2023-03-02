{{/* default containers volumes etc */}}
{{- define "default.containers" }}
## Source: _default.tpl
{{- end }}
{{- define "default.volumes" }}
## Source: _default.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "default.extras" }}
## Source: _default.tpl
{{- end }}