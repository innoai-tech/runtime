package appconfig

import (
	"sort"
	"strings"
)

func ParseAppConfig(s string) AppConfig {
	parts := strings.Split(s, ",")

	c := AppConfig{}

	for i := range parts {
		kv := strings.Split(parts[i], "=")

		if kv[0] == "" {
			continue
		}

		if len(kv) == 2 {
			c[kv[0]] = kv[1]
		} else {
			c[kv[0]] = ""
		}
	}

	return c
}

type AppConfig map[string]string

const AppConfigPrefx = "APP_CONFIG__"

func (c AppConfig) LoadFromEnviron(kv []string) {
	for i := range kv {
		keyValue := strings.SplitN(kv[i], "=", 2)
		key := keyValue[0]
		if len(keyValue) >= 2 && strings.HasPrefix(key, AppConfigPrefx) {
			c[key[len(AppConfigPrefx):]] = keyValue[1]
		}
	}
}

func (c AppConfig) String() string {
	keys := make([]string, 0)

	for k := range c {
		keys = append(keys, k)
	}

	sort.Strings(keys)

	b := strings.Builder{}

	for i, k := range keys {
		if i != 0 {
			b.WriteByte(',')
		}
		b.WriteString(k)
		b.WriteByte('=')
		b.WriteString(c[k])
	}

	return b.String()
}
