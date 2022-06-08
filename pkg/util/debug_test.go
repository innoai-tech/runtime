package util_test

import (
	"os"
	"testing"
	"text/template"
)

var tpl = `{{ 
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
{{ end }}`

func Test(t *testing.T) {
	tt, _ := template.New("x").Parse(tpl)

	err := tt.Execute(os.Stdout, map[string]any{
		"s":    1,
		"list": []any{"a", "b"},
		"o": map[string]any{
			"x": 1,
			"list": []any{
				map[string]any{
					"x": 1,
				},
				map[string]any{
					"x": 2,
				},
			},
		},
	})

	t.Log(err)
}
