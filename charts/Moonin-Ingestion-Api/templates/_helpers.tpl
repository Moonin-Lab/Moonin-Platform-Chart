{{- define "moonin-ingestion-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "moonin-ingestion-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "moonin-ingestion-api.fullname" -}}
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
{{- end }}

{{- define "moonin-ingestion-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moonin-ingestion-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "moonin-ingestion-api.labels" -}}
helm.sh/chart: {{ include "moonin-ingestion-api.chart" . }}
{{ include "moonin-ingestion-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: ingestion-api
{{- end }}

{{- define "moonin-ingestion-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "moonin-ingestion-api.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "moonin-ingestion-api.workerServiceAccountName" -}}
{{- if .Values.workers.serviceAccount.create -}}
{{- default (printf "%s-workers" (include "moonin-ingestion-api.fullname" .)) .Values.workers.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.workers.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "moonin-ingestion-api.queryName" -}}
{{- printf "%s-query" (default .Chart.Name .Values.nameOverride) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "moonin-ingestion-api.queryFullname" -}}
{{- if .Values.fullnameOverride -}}
{{- printf "%s-query" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-query" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "moonin-ingestion-api.querySelectorLabels" -}}
app.kubernetes.io/name: {{ include "moonin-ingestion-api.queryName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: query-api
{{- end }}

{{- define "moonin-ingestion-api.queryLabels" -}}
helm.sh/chart: {{ include "moonin-ingestion-api.chart" . }}
{{ include "moonin-ingestion-api.querySelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "moonin-ingestion-api.queryServiceAccountName" -}}
{{- if .Values.queryApi.serviceAccount.create -}}
{{- default (include "moonin-ingestion-api.queryFullname" .) .Values.queryApi.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.queryApi.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "moonin-ingestion-api.queryRedisFullname" -}}
{{- printf "%s-redis" (include "moonin-ingestion-api.queryFullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
