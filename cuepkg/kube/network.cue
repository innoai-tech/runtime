package kube

#Service: {
	name: string

	selector: [Label=string]: string
	ports: [Name=string]:     int32
	clusterIP?: string

	expose?: {
		type: "NodePort"
	} | {
		type: "Ingress"
		host: string
		paths: [PortName=string]: string
	}
}
