{{- define "teapot.networkList" -}}
  {{- $networks := .Values.networks -}}

  {{- if regexMatch "^\\w*/\\w*$" $networks -}}
    {{- $networks_split := regexSplit "/" $networks -1 -}}
    {{- $net_name := index $networks_split 1 -}}
    {{- $net_ns :=  index $networks_split 0 -}}

    {{- /* collect and deduplicate all the interface info */ -}}
    {{- $interfaces := dict -}}
    {{- range $behavior := (.Values.behaviors) -}}
      {{- $spec := $behavior.spec | default (dict) -}}
      {{- $iface := $spec.iface -}}
      {{- $mac := $spec.mac -}}
      {{- if and $iface $mac -}}
        {{- $entry := dict "name" $net_name "namespace" $net_ns "interface" $iface "mac" $mac -}}
        {{- $entry := dict $iface $entry -}}
        {{- $interfaces := merge $interfaces $entry -}}
      {{- else if $iface -}}
        {{- $entry := dict "name" $net_name "namespace" $net_ns "interface" $iface -}}
        {{- $entry := dict $iface $entry -}}
        {{- $interfaces := merge $interfaces $entry -}}
      {{- else if $mac -}}
        {{- $iface := "net1" -}}
        {{- $entry := dict "name" $net_name "namespace" $net_ns "interface" $iface "mac" $mac -}}
        {{- $entry := dict $iface $entry -}}
        {{- $interfaces := merge $interfaces $entry -}}
      {{- end -}}
    {{- end -}}

    {{- if le (len $interfaces) 0 -}}
      {{- /* nothin doin so dump raw tyvm */ -}}
      {{- $networks -}}
    {{- else -}}
      {{- /* use the collection we just collected */ -}}
      {{- values $interfaces | toJson | quote -}}
    {{- end -}}
  {{- else -}}
    {{- /* they're doing summat fancy in there, so don't fk it up by being clever */ -}}
    {{- $networks -}}
  {{- end -}}
{{- end -}}
