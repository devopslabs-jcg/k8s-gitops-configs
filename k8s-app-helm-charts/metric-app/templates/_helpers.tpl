# /home/jcg/devops_project/k8s-gitops-configs/cd-argo/templates/_helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "cd-argo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If that's too long, we recommend you specify a value for .Values.fullnameOverride
*/}}
{{- define "cd-argo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as part of the labels
*/}}
{{- define "cd-argo.labels" -}}
helm.sh/chart: {{ include "cd-argo.chart" . }}
{{ include "cd-argo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "cd-argo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cd-argo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the chart.
*/}}
{{- define "cd-argo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "cd-argo.commonLabels" -}}
{{ include "cd-argo.labels" . }}
{{- end -}}
