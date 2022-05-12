package appconfig

import (
	"testing"

	. "github.com/onsi/gomega"
)

func TestAppConfig(t *testing.T) {
	ac := AppConfig{
		"KEY1": "VALUE1",
		"KEY2": "VALUE2",
	}

	t.Run("#String", func(t *testing.T) {
		NewWithT(t).Expect(ac.String()).To(Equal("KEY1=VALUE1,KEY2=VALUE2"))
	})

	t.Run("#LoadFromEnviron", func(t *testing.T) {
		e := AppConfig{}
		e.LoadFromEnviron([]string{"APP_CONFIG__KEY1=VALUE1", "APP_CONFIG__KEY2=VALUE2", "XX=Value=1"})

		NewWithT(t).Expect(e).To(Equal(ac))
	})

	t.Run("ParseAppConfig", func(t *testing.T) {
		e := ParseAppConfig(ac.String())
		NewWithT(t).Expect(e).To(Equal(ac))
	})
}
