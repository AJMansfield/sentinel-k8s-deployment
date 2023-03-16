{{/* inject packetbeat into the honeypot pod */}}
{{- define "packetbeat.containers" }}
## Source: _packetbeat.tpl
- name: packetbeat
  image: docker.elastic.co/beats/packetbeat:8.6.2
  args:
    - '-e'
    - '-c'
    - /etc/beat.yml
  volumeMounts:
    - mountPath: /usr/share/packetbeat/data
      name: beat-data
    - mountPath: /etc/beat.yml
      name: config
      readOnly: true
      subPath: beat.yml
    - mountPath: /mnt/elastic-internal/elasticsearch-certs
      name: elasticsearch-certs
      readOnly: true
    - mountPath: /mnt/elastic-internal/kibana-certs
      name: kibana-certs
      readOnly: true
{{- end }}
{{- define "packetbeat.volumes" }}
## Source: _packetbeat.tpl
- name: beat-data
  hostPath:
    path: /var/lib/{{ .Release.Namespace }}/{{ .Release.Name }}-packetbeat/packetbeat-data
    type: DirectoryOrCreate
- name: config
  secret:
    defaultMode: 292
    optional: false
    secretName: {{ .Release.Name }}-packetbeat-beat-packetbeat-config
- name: elasticsearch-certs
  secret:
    defaultMode: 420
    optional: false
    secretName: {{ .Release.Name }}-packetbeat-beat-es-ca
- name: kibana-certs
  secret:
    defaultMode: 420
    optional: false
    secretName: {{ .Release.Name }}-packetbeat-beat-kibana-ca
{{- end }}
{{- define "packetbeat.extras" }}
## Source: _packetbeat.tpl
# To ensure the appropriate packetbeat user and secrets all get done up:
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: {{ .Release.Name }}-packetbeat
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "teapot.labels" . | indent 4 }}
spec:
  type: packetbeat
  version: 8.6.2
{{ .Values.eck | toYaml | indent 2 }}
  deployment:
    replicas: 0
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-packetbeat
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "teapot.labels" . | indent 4 }}
data:
  packetbeat.yml: |-
    packetbeat.interfaces.device: net1
    packetbeat.interfaces.type: af_packet
{{- end }}
