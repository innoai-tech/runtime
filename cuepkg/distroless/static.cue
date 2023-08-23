package distroless

import (
	"wagon.octohelm.tech/core"
	"wagon.octohelm.tech/docker"
)

#Static: {
	platform: string

	_base_files: #BaseFiles & {
		"platform": platform
	}
	_netbase: #Netbase & {
		"platform": platform
	}
	_tzdata: #Tzdata & {
		"platform": platform
	}
	_ca_certificates: #CaCertificates & {
		"platform": platform
	}

	_etc_group:    #EtcGroup
	_etc_passwd:   #EtcPasswd
	_etc_nsswitch: #EtcNsswitch

	_merge: core.#Merge & {
		inputs: [
			_base_files.output,
			_netbase.output,
			_tzdata.output,
			_ca_certificates.output,
			_etc_group.output,
			_etc_passwd.output,
			_etc_nsswitch.output,
		]
	}

	output: docker.#Image & {
		"platform": platform
		"rootfs":   _merge.output
		"config": {
			env: {
				"PATH":          "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
				"SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt"
			}
		}
	}
}
