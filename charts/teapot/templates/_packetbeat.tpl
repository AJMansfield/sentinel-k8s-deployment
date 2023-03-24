{{/* inject packetbeat into the honeypot pod */}}
{{- define "packetbeat.containers" }}
## Source: templates/_packetbeat.tpl
- name: packetbeat
  image: docker.elastic.co/beats/packetbeat:8.6.2
  args:
    - '-e'
    - '-c'
    - /etc/beat.yml
  volumeMounts:
    - mountPath: /usr/share/packetbeat/data
      name: packetbeat-data
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
  securityContext:
    allowPrivilegeEscalation: true
    capabilities:
      add: ["NET_ADMIN", "NET_RAW"]
{{- end }}
{{- define "packetbeat.volumes" }}
## Source: templates/_packetbeat.tpl
- name: packetbeat-data
  emptyDir: {}
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
## Source: templates/_packetbeat.tpl
# To ensure the appropriate packetbeat user and secrets all get done up:
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: {{ .Release.Name }}-packetbeat
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
spec:
  type: packetbeat
  version: 8.6.2
{{ .Values.eck | toYaml | indent 2 }}
  config:
    packetbeat.interfaces.device: net1
    packetbeat.interfaces.type: af_packet
    packetbeat.interfaces.auto_promisc_mode: true
    # packetbeat.interfaces.bpf_filter: "ifname net1"
    setup.dashboards.enabled: true
    setup.template.enabled: true
    packetbeat.protocols:
    - type: icmp
      enabled: true
  deployment:
    replicas: 0
{{- end }}
