{{/* vim: set filetype=mustache: */}}

{{/*
Get the Let's Encrypt server URL to which certificate requests will be sent.
*/}}
{{- define "server-address" -}}
{{- if eq .Values.environment "staging" -}}
https://acme-staging-v02.api.letsencrypt.org/directory
{{- end -}}
{{- if eq .Values.environment "prod" -}}
https://acme-v02.api.letsencrypt.org/directory
{{- end -}}
{{- end -}}
