package distroless

import (
	"strings"

	"wagon.octohelm.tech/core"
)

#EtcNsswitch: core.#WriteFile & {
	path: "/etc/nsswitch.conf"
	contents: """
		#
		# Example configuration of GNU Name Service Switch functionality.
		# If you have the `glibc-doc-reference' and `info' packages installed, try:
		# `info libc "Name Service Switch"' for information about this file.
		
		passwd:         compat
		group:          compat
		shadow:         compat
		gshadow:        files
		
		hosts:          files dns
		networks:       files
		
		protocols:      db files
		services:       db files
		ethers:         db files
		rpc:            db files
		
		netgroup:       nis
		"""
}

#EtcGroup: #WriteEntryFile & {
	path:    "/etc/group"
	entries: #GroupEntries & {
		"root": _
		"nobody": gid:  #NOBODY
		"tty": gid:     5
		"staff": gid:   50
		"nonroot": gid: #NONROOT
	}
}

#EtcPasswd: #WriteEntryFile & {
	path:    "/etc/passwd"
	entries: #PasswdEntries & {
		"root": _
		"nobody": {
			username: "nobody"
			uid:      #NOBODY
			gid:      #NOBODY
			home:     "/nonexistent"
		}
		"nonroot": {
			username: "nonroot"
			uid:      #NONROOT
			gid:      #NONROOT
			home:     "/home/\(username)"
		}
	}
}

#WriteEntryFile: {
	path: string
	entries: [string]: {
		entry: string
		...
	}

	_write: core.#WriteFile & {
		"path":     path
		"contents": strings.Join([
				for e in entries {
				e.entry
			},
		], "\n")
	}

	output: _write.output
}

#GroupEntries: [Groupname=string]: #GroupEntry & {
	groupname: Groupname
}

#GroupEntry: {
	groupname: string | *"root"
	password:  string | *"x"
	gid:       int | *0
	members:   [...string] | *[]

	entry: strings.Join([
		groupname,
		password,
		"\(gid)",
		strings.Join(members, ","),
	], ":")
}

#PasswdEntries: [Username=string]: #PasswdEntry & {
	username: Username
}

#PasswdEntry: {
	username: string | *"root"
	password: string | *"x"
	gid:      int | *0
	uid:      int | *0
	info:     string | *"\(username)"
	home:     string | *"/root"
	shell:    string | *"/sbin/nologin"

	entry: strings.Join([
		username,
		password,
		"\(uid)",
		"\(gid)",
		info,
		home,
		shell,
	], ":")
}

#NONROOT: 65532
#NOBODY:  65534
