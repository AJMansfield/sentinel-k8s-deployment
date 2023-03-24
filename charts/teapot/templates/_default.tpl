{{/* default containers volumes etc */}}
{{- define "default.containers" }}
## Source: templates/_default.tpl
{{- end }}
{{- define "default.volumes" }}
## Source: templates/_default.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
{{- end }}
{{- define "default.extras" }}
## Source: templates/_default.tpl
{{- end }}