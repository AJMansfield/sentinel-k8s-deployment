{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/tanner/docker-compose.yml */}}
{{/* container spec and volumes for tanner-redis */}}
{{- define "tanner-redis.containers" }}
## Source: _tanner.tpl
- image: dtagdevsec/redis:2204
  name: tanner-redis
{{- end }}
{{- define "tanner-redis.volumes" }}
## Source: _tanner.tpl
[]
{{- end }}
{{- define "tanner-redis.extras" }}
## Source: _tanner.tpl
{{- end }}
{{/* container spec and volumes for tanner-phpox */}}
{{- define "tanner-phpox.containers" }}
## Source: _tanner.tpl
- image: dtagdevsec/phpox:2204
  name: tanner-phpox
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /tmp
    name: tanner-phpox-tmp
{{- end }}
{{- define "tanner-phpox.volumes" }}
## Source: _tanner.tpl
- emptyDir:
    medium: Memory
  name: tanner-phpox-tmp
{{- end }}
{{- define "tanner-phpox.extras" }}
## Source: _tanner.tpl
{{- end }}
{{/* container spec and volumes for tanner-api */}}
{{- define "tanner-api.containers" }}
## Source: _tanner.tpl
- image: dtagdevsec/tanner:2204
  name: tanner-api
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/tanner
    name: data
    subPath: tanner/log
  - mountPath: /tmp/tanner
    name: tanner-api-tmp-tanner
{{- end }}
{{- define "tanner-api.volumes" }}
## Source: _tanner.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: tanner-api-tmp-tanner
{{- end }}
{{- define "tanner-api.extras" }}
## Source: _tanner.tpl
{{- end }}
{{/* container spec and volumes for tanner */}}
{{- define "tanner.containers" }}
## Source: _tanner.tpl
- image: dtagdevsec/tanner:2204
  name: tanner
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/tanner
    name: data
    subPath: tanner/log
  - mountPath: /opt/tanner/files
    name: data
    subPath: tanner/files
  - mountPath: /tmp/tanner
    name: tanner-tmp-tanner
{{- end }}
{{- define "tanner.volumes" }}
## Source: _tanner.tpl
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: tanner-tmp-tanner
{{- end }}
{{- define "tanner.extras" }}
## Source: _tanner.tpl
{{- end }}
{{/* container spec and volumes for snare */}}
{{- define "snare.containers" }}
## Source: _tanner.tpl
- image: dtagdevsec/snare:2204
  name: snare
{{- end }}
{{- define "snare.volumes" }}
## Source: _tanner.tpl
[]
{{- end }}
{{- define "snare.extras" }}
## Source: _tanner.tpl
{{- end }}
