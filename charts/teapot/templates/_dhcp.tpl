{{/* container spec and volumes for dhcp client */}}
{{- define "dhcp.containers" }}
## Source: templates/_dhcp.tpl
- name: dhcp
  image: alpine
  command: [
    "udhcpc",
    "-i", "{{ .Spec.iface | default "net1" }}", # Interface to use
    "-B", # Request broadcast replies (so everyone sees us)
    "-T", "5", # Pause between packets
    "-R", # Release IP on exit
    "-f", # Run in foreground
    "-a", # Validate offerred address with ARP ping (so everyone sees us)
    "-O", "12", # request Host Name
    "-O", "15", # request Domain Name
    "-O", "42", # request NTP Servers
    "-O", "119", # request Doman Search
    "-O", "120", # request SIP Servers
    "-x", "hostname:{{ .Spec.hostname | default .Values.hostname }}", # provide option 22
    "-F", "{{  .Spec.hostname | default .Values.hostname }}", # Ask server to update DNS mapping 
    "-V", "{{  .Spec.vendor | default "" }}", # Vendor identifier (replacing udhcp version info)
  ]
  lifecycle:
    postStart:
      exec:
        command:
        - /bin/sh
        - -c
        - |
          while [ ! -f /var/lease-acquired ] ; do
            sleep 0.1
          done
  volumeMounts:
  - name: udhcpc-scripts
    mountPath: "/usr/share/udhcpc"
  - name: resolv
    mountPath: /etc/resolv.d/
  securityContext:
    allowPrivilegeEscalation: true
    capabilities:
      add: ["NET_BIND_SERVICE", "NET_BROADCAST", "NET_ADMIN"]
{{- end }}
{{- define "dhcp.volumes" }}
## Source: templates/_dhcp.tpl
- name: udhcpc-scripts
  configMap:
    name: {{ .Release.Name }}-udhcpc-scripts
    defaultMode: 0700
- name: resolv
  emptyDir:
    medium: Memory
{{- end }}
{{- define "dhcp.extras" }}
## Source: templates/_dhcp.tpl
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-udhcpc-scripts
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
data:
{{ (.Files.Glob "files/udhcpc/*.script").AsConfig | indent 2 }}
{{- end }}
