{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/wordpot/docker-compose.yml */}}
{{/* container spec and volumes for wordpot */}}
{{- define "wordpot.containers" }}
- image: dtagdevsec/wordpot:2204
  name: wordpot
{{- end }}
{{- define "wordpot.volumes" }}
[]
{{- end }}
{{- define "wordpot.extras" }}
{{- end }}
