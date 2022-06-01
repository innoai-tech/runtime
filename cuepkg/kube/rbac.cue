package kube

import (
	rbac_v1 "k8s.io/api/rbac/v1"
)

#ServiceAccount: {
	role: "ClusterRole" | "Role"
	rules: [...rbac_v1.#PolicyRule]
}

_fromServiceAccount: {
	name:           string
	serviceAccount: #ServiceAccount

	kube: #Spec & {
		serviceAccounts: "\(name)": _

		if serviceAccount.role == "ClusterRole" {
			{
				clusterRoles: "\(name)": rbac_v1.#ClusterRole & {
					rules: serviceAccount.rules
				}

				clusterRoleBindings: "\(name)": rbac_v1.#ClusterRoleBinding & {
					subjects: [{
						"kind":      "ServiceAccount"
						"name":      name
						"namespace": serviceAccounts["\(name)"].metadata.namespace
					}]
					roleRef: {
						"kind":     "ClusterRole"
						"name":     name
						"apiGroup": "rbac.authorization.k8s.io"
					}
				}
			}
		}

		if serviceAccount.role == "Role" {
			{
				roles: "\(name)": rbac_v1.#Role & {
					rules: serviceAccount.rules
				}
				roleBindings: "\(name)": rbac_v1.#RoleBinding & {
					subjects: [{
						"kind":      "ServiceAccount"
						"name":      "\(name)"
						"namespace": serviceAccounts["\(name)"].metadata.namespace
					}]
					roleRef: {
						"kind":     "Role"
						"name":     "\(name)"
						"apiGroup": "rbac.authorization.k8s.io"
					}
				}
			}
		}
	}
}
