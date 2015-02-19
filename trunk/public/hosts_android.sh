#!/bin/bash

_remount_dir="/system"
_hosts_file="/system/etc/hosts"

# check if file exists
if [ ! -e hosts.txt ]; then
	echo "Either hosts.txt is missing or script was called from wrong path" 1>&2
	exit 1
fi

# check if root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# remount system dir writeable
mount -o rw,remount "${_remount_dir}"

# backup old hosts file
cp "${_hosts_file}" "${_hosts_file}.bak"

# writing hosts file
cat hosts.txt > "${_hosts_file}"

# remount system dir readable
mount -o r,remount "${_remount_dir}"

echo "Hosts file has been updated. The ads should be gone now."
