package imagetool

#Project: {
	version:  string | *"dev"
	revision: string | *""
	mirror:   #Mirror
	auths: [Host=string]: #Auth

	ship: #Ship

	ship: "auths":  auths
	ship: "mirror": mirror
	...
}
