#!/bin/bash

_remount_dir="/system"
_hosts_file="/system/etc/hosts"
_path=`dirname $0`

# check if root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# remount system dir as root
mount -o rw,remount "${_remount_dir}"

# writing hosts file
cat "$_path/hosts.txt" > "${_hosts_file}"

echo "Hosts file has been updated. The ads should be gone now."
