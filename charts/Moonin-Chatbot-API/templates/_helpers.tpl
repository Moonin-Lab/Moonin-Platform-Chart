{{- define "moonin-chatbot-api.fullname" -}}{{ .Release.Name }}-moonin-chatbot-api{{- end -}}
{{- define "moonin-chatbot-api.selectorLabels" -}}
app.kubernetes.io/name: moonin-chatbot-api
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
