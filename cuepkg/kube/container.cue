package kube

import (
	"strings"
	core_v1 "k8s.io/api/core/v1"
)

#Container: {
	name: string
	image: {
		name:       string
		tag:        string
		pullPolicy: core_v1.#PullPolicy | *"\(core_v1.#PullIfNotPresent)"
	}
	env: [string]:   string | #EnvFromSource
	ports: [string]: int32
	command?: [...string]
	args?: [...string]
	workingDir?:               string
	resources?:                core_v1.#ResourceRequirements
	livenessProbe?:            core_v1.#Probe
	readinessProbe?:           core_v1.#Probe
	startupProbe?:             core_v1.#Probe
	lifecycle?:                core_v1.#Lifecycle
	terminationMessagePath?:   string
	terminationMessagePolicy?: core_v1.#TerminationMessagePolicy
	securityContext?:          core_v1.#SecurityContext
	stdin?:                    bool
	stdinOnce?:                bool
	tty?:                      bool
}

_fromContainer: {
	container: #Container
	volumes: [N=string]: #Volume

	kube: core_v1.#Container & {
		for k, v in container if !( k == "image" || k == "ports" || k == "env") {
			"\(k)": v
		}
		image:           "\(container.image.name):\(container.image.tag)"
		imagePullPolicy: container.image.pullPolicy
		ports: [
			for n, cp in container.ports {
				name:          n
				containerPort: cp
				[
					if strings.HasPrefix(n, "udp") {
						{protocol: "UDP"}
					},
					{protocol: "TCP"},
				][0]
			},
		]
		env: [
			for _name, _value in container.env {
				let _isStrValue = (_value & string) != _|_
				[
					if (_isStrValue) {
						name:  _name
						value: _value
					},
					if (!_isStrValue) {
						name: _name
						valueFrom: {
							for _type, _refKey in _value.from
							for _ref, _key in _refKey {
								[
									if _type == "secret" {
										secretKeyRef: {
											name: _ref
											key:  [ if _key == "" {_name}, _key][0]
										}
									},
									if _type == "configMap" {
										configMapKeyRef: {
											name: _ref
											key:  [ if _key == "" {_name}, _key][0]
										}
									},
									if _type == "field" {
										fieldRef: {
											fieldPath: _ref
										}
									},
									if _type == "resourceField" {
										resourceFieldRef: {
											resource: _ref
										}
									},
								][0]
							}
						}
					},
				][0]
			},
		]
		volumeMounts: [
			for n, vol in volumes {
				name: n
				for k, v in vol if k != "source" {
					"\(k)": v
				}
			},
		]
	}
}

#EnvFromSource: {
	from: configMap: [Name=string]:     string
	from: secret: [Name=string]:        string
	from: field: [Name=string]:         string
	from: resourceField: [Name=string]: string
}

#ProbeHttpGet: core_v1.#Probe & {
	httpGet: {
		scheme: _ | *"HTTP"
	}
	initialDelaySeconds: _ | *5
	timeoutSeconds:      _ | *1
	periodSeconds:       _ | *10
	successThreshold:    _ | *1
	failureThreshold:    _ | *3
}
