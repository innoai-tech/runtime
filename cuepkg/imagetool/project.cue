package imagetool

#Project: {
	version:  string | *"dev"
	revision: string | *""

	auths: [Host=string]: #Auth

	ship?: #Ship & {
		"auths": auths
	}

	...
}
