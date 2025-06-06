{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "oathkeeper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oathkeeper.fullname" -}}
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
Generate the configmap data, redacting secrets
*/}}
{{- define "oathkeeper.configmap" -}}
{{- $config := .Values.oathkeeper.config -}}
{{-  if .Values.oathkeeper.helmTemplatedConfigEnabled -}}
{{- tpl (toYaml $config) . -}}
{{- else -}}
{{- toYaml $config -}}
{{- end -}}
{{- end -}}

{{/*
Create a name which can be overridden.
*/}}
{{- define "oathkeeper.configmap.name" -}}
{{- if .Values.oathkeeper.configFileOverride.nameOverride -}}
{{- .Values.oathkeeper.configFileOverride.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ include "oathkeeper.fullname" . }}-config
{{- end -}}
{{- end -}}

{{/*
Create a config map name for rules.
If maester is enabled, use the child chart named template to get the value.
*/}}
{{- define "oathkeeper.rulesConfigMapName" -}}
	{{- if .Values.maester.enabled -}}
		{{- $childChart := (dict "Name" "oathkeeper-maester") -}}
		{{- include "oathkeeper-maester.getCM" (dict "Values" (index .Values "oathkeeper-maester") "Release" $.Release "Chart" $childChart) }}
	{{- else -}}
		{{- if .Values.oathkeeper.accessRulesOverride.nameOverride -}}
			{{- .Values.oathkeeper.accessRulesOverride.nameOverride | trunc 63 | trimSuffix "-" -}}
		{{- else -}}
			{{ include "oathkeeper.fullname" . }}-rules
		{{- end -}}
	{{- end -}}
{{- end -}}


{{/*
Create a secret name which can be overridden.
*/}}
{{- define "oathkeeper.secretname" -}}
{{- if .Values.secret.nameOverride -}}
{{- .Values.secret.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ include "oathkeeper.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "oathkeeper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "oathkeeper.labels" -}}
app.kubernetes.io/name: {{ include "oathkeeper.name" . }}
helm.sh/chart: {{ include "oathkeeper.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Check overrides consistency
*/}}
{{- define "oathkeeper.check.override.consistency" -}}
{{- if and .Values.maester.enabled .Values.fullnameOverride -}}
{{- if not .Values.maester.oathkeeperFullnameOverride -}}
{{ fail "oathkeeper fullname has been overridden, but the new value has not been provided to maester. Set maester.oathkeeperFullnameOverride" }}
{{- else if not (eq .Values.maester.oathkeeperFullnameOverride .Values.fullnameOverride) -}}
{{ fail (tpl "oathkeeper fullname has been overridden, but a different value was provided to maester. {{ .Values.maester.oathkeeperFullnameOverride }} different of {{ .Values.fullnameOverride }}" . ) }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "oathkeeper.serviceAccountName" -}}
{{- if .Values.deployment.serviceAccount.create }}
{{- default (include "oathkeeper.fullname" .) .Values.deployment.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.deployment.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Checksum annotations generated from configmaps and secrets
*/}}
{{- define "oathkeeper.annotations.checksum" -}}
{{- if .Values.configmap.hashSumEnabled }}
{{- $oathkeeperConfigMapFile := ternary "/configmap-config-demo.yaml" "/configmap-config.yaml" (.Values.demo) }}
checksum/oathkeeper-config: {{ include (print $.Template.BasePath $oathkeeperConfigMapFile) . | sha256sum }}
{{- if .Values.oathkeeper.managedAccessRules }}
checksum/oathkeeper-rules: {{ include (print $.Template.BasePath "/configmap-rules.yaml") . | sha256sum }}
{{- end }}
{{- end }}
{{- if and .Values.secret.enabled .Values.secret.hashSumEnabled }}
checksum/oauthkeeper-secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end }}
{{- end }}

{{/*
Generate the secrets.annotations value
*/}}
{{- define "oathkeeper.secrets.annotations" -}}
  {{- $annotations := dict -}}
  {{- if .Values.secret.enableDefaultAnnotations }}
    {{- $annotations = .Values.secret.secretAnnotations -}}
  {{- end -}}
  {{- $annotations = merge $annotations .Values.secret.extraAnnotations -}}
  {{- toYaml $annotations }}
{{- end -}}
