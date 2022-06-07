package kubepkg

import (
	"github.com/innoai-tech/runtime/cuepkg/kube"
)

#KubePkg: {
	apiVersion: "octohelm.tech/v1alpha1"
	kind:       "KubePkg"

	metadata: namespace: string
	metadata: name:      string

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

		spec: {
			version: kubeapp.app.version
			images: {
				for n, c in kubeapp.containers {
					"\(c.image.name):\(c.image.tag)": ""
				}
			}
			manifests: (kubeapp.kube & {
				"namespace": {
					metadata: name: namespace
				}
			})
		}
	}
}
