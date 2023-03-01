{{/* derived from https://github.com/telekom-security/tpotce/tree/master/docker/conpot/docker-compose.yml */}}
{{/* container spec and volumes for conpot-default */}}
{{- define "conpot-default.containers" }}
- env:
  - CONPOT_CONFIG=/etc/conpot/conpot.cfg
  - CONPOT_JSON_LOG=/var/log/conpot/conpot_default.json
  - CONPOT_LOG=/var/log/conpot/conpot_default.log
  - CONPOT_TEMPLATE=default
  - CONPOT_TMP=/tmp/conpot
  image: dtagdevsec/conpot:2204
  name: conpot-default
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/conpot
    name: data
    subPath: conpot/log
  - mountPath: /tmp/conpot
    name: conpot-default-tmp-conpot
{{- end }}
{{- define "conpot-default.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: conpot-default-tmp-conpot
{{- end }}
{{- define "conpot-default.extras" }}
{{- end }}
{{/* container spec and volumes for conpot-iec104 */}}
{{- define "conpot-iec104.containers" }}
- env:
  - CONPOT_CONFIG=/etc/conpot/conpot.cfg
  - CONPOT_JSON_LOG=/var/log/conpot/conpot_IEC104.json
  - CONPOT_LOG=/var/log/conpot/conpot_IEC104.log
  - CONPOT_TEMPLATE=IEC104
  - CONPOT_TMP=/tmp/conpot
  image: dtagdevsec/conpot:2204
  name: conpot-iec104
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/conpot
    name: data
    subPath: conpot/log
  - mountPath: /tmp/conpot
    name: conpot-iec104-tmp-conpot
{{- end }}
{{- define "conpot-iec104.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: conpot-iec104-tmp-conpot
{{- end }}
{{- define "conpot-iec104.extras" }}
{{- end }}
{{/* container spec and volumes for conpot-guardian-ast */}}
{{- define "conpot-guardian-ast.containers" }}
- env:
  - CONPOT_CONFIG=/etc/conpot/conpot.cfg
  - CONPOT_JSON_LOG=/var/log/conpot/conpot_guardian_ast.json
  - CONPOT_LOG=/var/log/conpot/conpot_guardian_ast.log
  - CONPOT_TEMPLATE=guardian_ast
  - CONPOT_TMP=/tmp/conpot
  image: dtagdevsec/conpot:2204
  name: conpot-guardian-ast
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/conpot
    name: data
    subPath: conpot/log
  - mountPath: /tmp/conpot
    name: conpot-guardian-ast-tmp-conpot
{{- end }}
{{- define "conpot-guardian-ast.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: conpot-guardian-ast-tmp-conpot
{{- end }}
{{- define "conpot-guardian-ast.extras" }}
{{- end }}
{{/* container spec and volumes for conpot-ipmi */}}
{{- define "conpot-ipmi.containers" }}
- env:
  - CONPOT_CONFIG=/etc/conpot/conpot.cfg
  - CONPOT_JSON_LOG=/var/log/conpot/conpot_ipmi.json
  - CONPOT_LOG=/var/log/conpot/conpot_ipmi.log
  - CONPOT_TEMPLATE=ipmi
  - CONPOT_TMP=/tmp/conpot
  image: dtagdevsec/conpot:2204
  name: conpot-ipmi
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/conpot
    name: data
    subPath: conpot/log
  - mountPath: /tmp/conpot
    name: conpot-ipmi-tmp-conpot
{{- end }}
{{- define "conpot-ipmi.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: conpot-ipmi-tmp-conpot
{{- end }}
{{- define "conpot-ipmi.extras" }}
{{- end }}
{{/* container spec and volumes for conpot-kamstrup-382 */}}
{{- define "conpot-kamstrup-382.containers" }}
- env:
  - CONPOT_CONFIG=/etc/conpot/conpot.cfg
  - CONPOT_JSON_LOG=/var/log/conpot/conpot_kamstrup_382.json
  - CONPOT_LOG=/var/log/conpot/conpot_kamstrup_382.log
  - CONPOT_TEMPLATE=kamstrup_382
  - CONPOT_TMP=/tmp/conpot
  image: dtagdevsec/conpot:2204
  name: conpot-kamstrup-382
  securityContext:
    fsGroup: 2000
    runAsGroup: 2000
    runAsUser: 2000
  volumeMounts:
  - mountPath: /var/log/conpot
    name: data
    subPath: conpot/log
  - mountPath: /tmp/conpot
    name: conpot-kamstrup-382-tmp-conpot
{{- end }}
{{- define "conpot-kamstrup-382.volumes" }}
- name: data
  persistentVolumeClaim:
    claimName: '{{ .Release.Name }}-data'
- emptyDir:
    medium: Memory
  name: conpot-kamstrup-382-tmp-conpot
{{- end }}
{{- define "conpot-kamstrup-382.extras" }}
{{- end }}
