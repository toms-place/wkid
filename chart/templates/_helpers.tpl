{{/*
Expand the name of the chart.
*/}}
{{- define "wkid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wkid.fullname" -}}
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
{{- define "wkid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wkid.labels" -}}
helm.sh/chart: {{ include "wkid.chart" . }}
{{ include "wkid.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wkid.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wkid.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: wkid
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wkid.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wkid.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the configmap to use
*/}}
{{- define "wkid.configMap" -}}
{{- default (include "wkid.fullname" .) .Values.configMap.name }}
{{- end }}

{{/*
Get the first ingress or httproute hostname
*/}}
{{- define "wkid.hostname" -}}
{{- if .Values.ingress.enabled -}}
{{- range .Values.ingress.hosts -}}
{{- .host -}}
{{- break -}}
{{- end -}}
{{- else if .Values.httpRoute.enabled -}}
{{- range .Values.httpRoute.hostnames -}}
{{- . -}}
{{- break -}}
{{- end -}}
{{- else -}}
{{- "chart-example.local" -}}
{{- end -}}
{{- end }}
