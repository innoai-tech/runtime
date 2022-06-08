package tool

import (
	"text/template"
)

_t: """
	{{ 
	define "toml" }}{{ 
		if (eq "map[string]interface {}" (printf "%T" .)) 
	}}{ {{ 	
			$i := 0 }}{{ 
			range $key, $value := .
	}}{{ 
			if (ne 0 $i) }}, {{ end 
	}}{{ 		printf "%q" $key  }} = {{ template "toml" $value }}{{
				$i = 1
	}}{{ 
			end }} }{{ 
		else if (eq "[]interface {}" (printf "%T" .) )
	}}[ {{ range $i, $value := . }}{{ if (ne 0 $i) }}, {{ end }}{{ template "toml" $value }}{{ end }} ]{{
		else if eq "string" (printf "%T" .) 
	}}{{ 	printf "%q" .  }}{{
		else 
	}}{{ 	printf "%v" .  }}{{
		end }}{{ 
	end 
	}}{{ 
	range $key, $value := . }}{{ printf "%q" $key }} = {{ template "toml" $value }}
	{{ end }}"""

#ToToml: {
	input:  _
	output: template.Execute(_t, input)
}
