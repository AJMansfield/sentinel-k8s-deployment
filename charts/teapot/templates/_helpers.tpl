{{/*
Expand the name of the chart.
*/}}
{{- define "teapot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "teapot.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "teapot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "teapot.labels" -}}
helm.sh/chart: {{ include "teapot.chart" . }}
{{ include "teapot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "teapot.selectorLabels" -}}
app.kubernetes.io/part-of: sentinel
app.kubernetes.io/name: {{ include "teapot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Specific specializations
*/}}
{{- define "teapot.logLabels" -}}
{{ include "teapot.labels" . }}
app.kubernetes.io/component: logging
{{- end }}

{{- define "teapot.potLabels" -}}
{{ include "teapot.labels" . }}
app.kubernetes.io/component: honeypot
{{- end }}

{{- define "teapot.logSelectorLabels" -}}
{{ include "teapot.selectorLabels" . }}
app.kubernetes.io/component: logging
{{- end }}

{{- define "teapot.potSelectorLabels" -}}
{{ include "teapot.selectorLabels" . }}
app.kubernetes.io/component: honeypot
{{- end }}