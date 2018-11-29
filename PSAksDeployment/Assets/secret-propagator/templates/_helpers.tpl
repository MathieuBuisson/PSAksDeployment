{{/* vim: set filetype=mustache: */}}

{{/* Generate selector argument for kubectl command, based selector key and value */}}
{{- define "secret-propagator.selector" -}}
{{- .Values.selector.key -}}={{- .Values.selector.value -}}
{{- end -}}

{{/* kubectl arguments to output only name values from a "kubectl get" query */}}
{{- define "secret-propagator.getNames" -}}
--no-headers -o "custom-columns=:metadata.name"
{{- end -}}
