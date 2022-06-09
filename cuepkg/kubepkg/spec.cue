package kubepkg

import (
	"strings"

	"github.com/innoai-tech/runtime/cuepkg/kube"
)

#KubePkg: {
	apiVersion: "octohelm.tech/v1alpha1"
	kind:       "KubePkg"

	metadata: namespace: string
	metadata: name:      string
	metadata: labels: [N=string]:      string
	metadata: annotations: [N=string]: string

	spec: {
		version: string
		images: [Name=string]: string
		manifests: _
	}
}

#FromKubeApp: {
	namespace: string
	kubeapp:   kube.#App

	output: #KubePkg & {
		metadata: "namespace": namespace
		metadata: name:        kubeapp.app.name
		metadata: name:        kubeapp.app.name

		if len(kubeapp.platforms) > 0 {
			metadata: annotations: "octohelm.tech/platform": strings.Join(kubeapp.platforms, ",")
		}

		spec: {
			version: kubeapp.app.version
			images: {
				for n, c in kubeapp.containers {
					"\(c.image.name):\(c.image.tag)": ""
				}
			}
			manifests: (kubeapp.kube & {
				"namespace": metadata: name: namespace
			})
		}
	}
}
