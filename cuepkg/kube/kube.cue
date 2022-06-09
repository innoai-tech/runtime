package kube

import (
	core_v1 "k8s.io/api/core/v1"
	apps_v1 "k8s.io/api/apps/v1"
	networking_v1 "k8s.io/api/networking/v1"
	rbac_v1 "k8s.io/api/rbac/v1"
)

#Spec: {
	namespace: core_v1.#Namespace & {
		metadata: name: string | *"default"
	}

	// networks
	services: [Name = string]: core_v1.#Service & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	ingresses: [Name = string]: networking_v1.#Ingress & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	// configuration & storage
	persistentVolumeClaims: [Name = string]: core_v1.#PersistentVolumeClaim & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	configMaps: [Name = string]: core_v1.#ConfigMap & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	secrets: [Name = string]: core_v1.#Secret & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
		type: string | *"Opaque"
	}

	// workload
	deployments: [Name = string]: apps_v1.#Deployment & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
		metadata: labels: app: Name
		spec: template: metadata: labels: app: Name
		spec: selector: matchLabels: app: Name
	}

	daemonSets: [Name = string]: apps_v1.#DaemonSet & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
		metadata: labels: app: Name
		spec: template: metadata: labels: app: Name
		spec: selector: matchLabels: app: Name
	}

	statefulSets: [Name = string]: apps_v1.#StatefulSet & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
		metadata: labels: app: Name
		spec: template: metadata: labels: app: Name
		spec: selector: matchLabels: app: Name
	}

	// rbac
	serviceAccounts: [Name=string]: core_v1.#ServiceAccount & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	clusterRoles: [Name=string]: rbac_v1.#ClusterRole & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	clusterRoleBindings: [Name=string]: rbac_v1.#ClusterRoleBinding & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	roles: [Name=string]: rbac_v1.#Role & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}

	roleBindings: [Name=string]: rbac_v1.#RoleBinding & {
		metadata: name:        Name
		metadata: "namespace": namespace.metadata.name
	}
}
