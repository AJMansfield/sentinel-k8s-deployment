{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/wordpot/docker-compose.yml */}}
{{/* container spec and volumes for wordpot */}}
{{- define "wordpot.containers" }}
## Source: _wordpot.tpl
- image: dtagdevsec/wordpot:2204
  name: wordpot
{{- end }}
{{- define "wordpot.volumes" }}
## Source: _wordpot.tpl
[]
{{- end }}
{{- define "wordpot.extras" }}
## Source: _wordpot.tpl
{{- end }}
