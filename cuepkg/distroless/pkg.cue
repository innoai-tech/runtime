package distroless

// https://packages.debian.org/bookworm/amd64/base-files/filelist
#BaseFiles: #Extract & {
	packages: {
		"base-files": _
	}
}

#Netbase: #Extract & {
	packages: {
		"netbase": _
	}
}

#CaCertificates: #Extract & {
	packages: {
		"ca-certificates": _
	}
	include: [
		// openssl deps
		"etc/ssl/certs/",
	]
	exclude: [
		"etc/ca-certificates/update.d",
		"usr/sbin/update-ca-certificates",
		"usr/share/man"
	]
}

#Tzdata: #Extract & {
	packages: {
		"tzdata": _
	}
}
