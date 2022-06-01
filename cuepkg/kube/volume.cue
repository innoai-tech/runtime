package kube

import (
	core_v1 "k8s.io/api/core/v1"
)

#Volume: {
	core_v1.#VolumeMount
	source: {
		type: "emptyDir"
		core_v1.#EmptyDirVolumeSource
	} | {
		type: "hostPath"
		core_v1.#HostPathVolumeSource
	} | {
		type: "secret"
		core_v1.#SecretVolumeSource
		spec: core_v1.#Secret
	} | {
		type: "configMap"
		core_v1.#ConfigMapVolumeSource
		spec: core_v1.#ConfigMap
	} | {
		type: "persistentVolumeClaim"
		core_v1.#PersistentVolumeClaimVolumeSource
		spec: core_v1.#PersistentVolumeClaimSpec
	}
}
