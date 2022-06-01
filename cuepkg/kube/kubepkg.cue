package kube

#KubePkg: {
	app:       #App
	namespace: string

	kube: {
		apiVersion: "octohelm.tech/v1alpha1"
		kind:       "KubePkg"
		metadata: "namespace": namespace
		metadata: name:        app.app.name

		spec: {
			version: app.app.version
			images: {
				for n, c in app.containers {
					"\(c.image.name):\(c.image.tag)": ""
				}
			}
			manifests: (app.kube & {
				"namespace": {
					metadata: name: namespace
				}
			})
		}
	}
}
