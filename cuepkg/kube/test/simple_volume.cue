package test

import (
	"github.com/innoai-tech/runtime/cuepkg/kube"
)

{
	MountVolume: {
		actual: kube.#App & {
			app: {
				name:    "web"
				version: "alpine"
			}

			services: "\(app.name)": {
				selector: "app": "\(app.name)"
				ports: containers.web.ports
			}

			containers: web: {
				image: {
					name: "docker.io/libary/nginx"
					tag:  app.name
				}
				ports: http: 80
			}

			volumes: html: {
				mountPath: "/etc/nginx/html"
				source: {
					type: "configMap"
					name: "\(app.name)-html"
					spec: data: "index.html": "<div>hello</div>"
				}
			}
		}

		expect: "manifests should render": {
			deployment: actual.kube.deployments.web != _|_
			services:   actual.kube.services.web != _|_
			configMaps: actual.kube.configMaps."web-html" != _|_
		}

		expect: {
			"configMap.web-html should render": _|_ != (actual.kube.configMaps."web-html".data & {
				"index.html": "<div>hello</div>"
			})
			"containers[0].volumeMounts[0] should be web": _|_ != (actual.kube.deployments.web.spec.template.spec.containers[0].volumeMounts[0] & {
				mountPath: "/etc/nginx/html"
				name:      "html"
			})
			"containers[0].volumeMounts[0] should be web": _|_ != (actual.kube.deployments.web.spec.template.spec.volumes[0] & {
				name: "html"
				configMap: name: "web-html"
			})
		}
	}
}
