{{- define "samba.sub.extras.auditbeat" }}
## Source: samba/_auditbeat.tpl
# Adapted from https://raw.githubusercontent.com/elastic/cloud-on-k8s/2.6/config/recipes/beats/auditbeat_hosts.yaml
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: {{ .Release.Name }}-samba-auditbeat
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.logLabels" . | nindent 4 }}
spec:
  type: auditbeat
  version: 8.5.2
{{ .Values.eck | toYaml | indent 2 }}
  config:
    auditbeat.modules:
    - module: auditd
      audit_rules: |
        -a always,exit -F dir=/shares/ -F perm=rwxa -F key={{ .Release.Name }}
  deployment:
    replicas: 1
    podTemplate:
      spec:
        hostPID: true  # Required by auditd module
        securityContext:
          runAsUser: 0
        containers:
        - name: auditbeat
          securityContext:
            capabilities:
              add: ['AUDIT_READ', 'AUDIT_WRITE', 'AUDIT_CONTROL']
          volumeMounts:
          - name: shares
            mountPath: "/shares"
            readOnly: true
        volumes:
        - name: shares
          persistentVolumeClaim:
            claimName: {{ .Release.Name }}-samba-shares
{{- end }}