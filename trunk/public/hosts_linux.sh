#!/bin/bash

_path=`dirname $0`

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

cat "$_path/hosts.txt" >> "/etc/hosts"
echo "Hosts file has been updated. The ads should be gone now."
