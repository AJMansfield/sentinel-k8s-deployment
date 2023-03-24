{{- define "samba.internal.mkall" }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-samba-mkall
  namespace: {{ .Release.Namespace }}
  labels: {{- include "teapot.potLabels" . | nindent 4 }}
spec:
  template:
    spec:
      containers:
      - name: mkall
        image: alpine
        command: ["/opt/mkall.sh","/opt/file_list.txt","/opt/dir_list.txt","/shares"]
        volumeMounts:
        - name: shares
          mountPath: /shares
        - name: mkall
          mountPath: /opt
      volumes:
      - name: shares
        persistentVolumeClaim:
          claimName: {{ .Release.Name }}-samba-shares
      - name: mkall
        configMap:
          name: {{ .Release.Name }}-samba-mkall
          defaultMode: 0700
{{- end }}