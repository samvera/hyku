{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "hyku.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hyku.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "hyku.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Shorthand for component names
*/}}

{{- define "hyku.postgres.name" -}}
{{- .Release.Name -}}-postgresql
{{- end -}}
{{- define "hyku.redis.name" -}}
{{- .Release.Name -}}-redis-master
{{- end -}}
{{- define "hyku.web.name" -}}
{{- include "hyku.fullname" . -}}-web
{{- end -}}
{{- define "hyku.sidekiq.name" -}}
{{- include "hyku.fullname" . -}}-sidekiq
{{- end -}}
{{- define "hyku.rails-env.name" -}}
{{- include "hyku.fullname" . -}}-rails-env
{{- end -}}
{{- define "hyku.postgres-env.name" -}}
{{- include "hyku.fullname" . -}}-postgres-env
{{- end -}}
{{- define "hyku.setup.name" -}}
{{- include "hyku.fullname" . -}}-setup
{{- end -}}
{{- define "hyku.zookeeper.name" -}}
{{- include "solr.zookeeper-service-name" . -}}
{{- end -}}
{{- define "hyku.zookeeper-env.name" -}}
{{- include "hyku.fullname" . -}}-zookeeper-env
{{- end -}}
{{- define "hyku.solr.name" -}}
{{- .Release.Name -}}-solr-svc
{{- end -}}

{{- define "hyku.solr.collection" -}}
{{- if eq .Values.env.configmap.SETTINGS__MULTITENANCY__ENABLED false }}single{{- end -}}
{{- end -}}

{{- define "hyku.fcrepo.name" -}}
{{- include "hyku.fullname" . -}}-fcrepo
{{- end -}}
{{- define "hyku.fcrepo-env.name" -}}
{{- include "hyku.fullname" . -}}-fcrepo-env
{{- end -}}
