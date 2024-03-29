package kube

import (
	"strings"
)

#App: {
	app: {
		name:    string
		version: string
	}

	platforms: [...string] | *["linux/amd64", "linux/arm64"]

	config: [Name=string]: _

	initContainers: [Name=string]: #Container & {
		name: Name

		envFrom: {
			configMap: "\(app.name)": _
			secret: "\(app.name)":    _
		}
	}

	containers: [Name=string]: #Container & {
		name: Name

		envFrom: {
			secret: "\(app.name)": _
		}
	}

	services: [Name=string]: #Service & {
		name: Name
	}

	volumes: [Name=string]: #Volume & {
		name: Name
	}

	type:            ( "Deployment" | "StatefulSet" | "DaemonSet" ) | *"Deployment"
	replicas:        int | *1
	serviceAccount?: #ServiceAccount

	kube: #Spec & {
		secrets: "\(app.name)": stringData: {}

		if len(config) > 0 {
			for k, v in config {
				[
					{secrets: "\(app.name)": stringData: "\(k)": "\(v)"},
				][0]
			}
		}

		for name, s in services {
			if (s.expose != _|_) {
				if s.expose.type == "Ingress" {
					ingresses: "\(name)": spec: rules: [{
						host: s.expose.host
						http: paths: [
							for portName, p in s.expose.paths {
								{
									pathType: "Exact"
									path:     p
									backend: service: {
										"name": name
										port: name: portName
									}
								}
							},
						]
					}]
				}
			}
			services: "\(name)": {
				let isNodePort = [
					if (s.expose != _|_ ) if s.expose.type == "NodePort" {true},
					false,
				][0]

				spec: selector: s.selector

				spec: ports: [
					for n, port in s.ports {
						name:       n
						targetPort: n
						[
							if strings.HasPrefix(n, "udp") {
								{protocol: "UDP"}
							},
							{protocol: "TCP"},
						][0]

						if port != _|_ {
							{
								"port": port

								if isNodePort {
									nodePort: port
								}
							}
						}

					},
				]

				if s.clusterIP != _|_ {
					spec: clusterIP: s.clusterIP
				}

				if isNodePort {
					spec: type: "NodePort"
				}
			}
		}

		for _, vol in volumes {
			if vol.source.type == "persistentVolumeClaim" {
				persistentVolumeClaims: "\(vol.source.claimName)": spec: vol.source.spec
			}
			if vol.source.type == "configMap" {
				configMaps: "\(vol.source.name)": vol.source.spec
			}
			if vol.source.type == "secret" {
				secrets: "\(vol.source.name)": vol.source.spec
			}
		}

		"\({
			"Deployment":  "deployments"
			"StatefulSet": "statefulSets"
			"DaemonSet":   "daemonSets"
		}[type])": "\(app.name)": {
			spec: "replicas": replicas

			spec: template: spec: {
				"initContainers": [
					for _, c in initContainers {
						(_fromContainer & {
							container: c
							"volumes": volumes
						}).kube
					},
				]

				"containers": [
					for _, c in containers {
						(_fromContainer & {
							container: c
							"volumes": volumes
						}).kube
					},
				]

				"volumes": [
					for n, vol in volumes {
						name: n
						"\(vol.source.type)": {
							for k, v in vol.source if !(k == "type" || k == "spec") {
								"\(k)": v
							}
						}
					},
				]
			}

			if len(platforms) > 0 {
				spec: template: spec: affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [
					{
						matchExpressions: [
							{
								key:      "kubernetes.io/arch"
								operator: "In"
								values: [
									for p in platforms {
										"\(strings.Split(p, "/")[1])"
									},
								]
							},
						]
					},
				]
			}

			if serviceAccount != _|_ {
				spec: template: spec: serviceAccount: app.name
			}
		}

		if serviceAccount != _|_ {
			(_fromServiceAccount & {
				name:             app.name
				"serviceAccount": serviceAccount
			}).kube
		}
	}
}
