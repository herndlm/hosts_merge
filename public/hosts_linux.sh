#!/bin/sh

ADBLOCK_URL="http://hosts.herndl.org/?src=all"
ADBLOCK_DOMAIN="hosts.herndl.org"
ADBLOCK_IP="81.19.156.28"
HOSTS_LOCATION="/etc/hosts"

# check if root (check if root is in id output as fallback on e.g. android)
if [ "$(id -u)" != "0" ] && case "`id`" in *"root"*) false;; *) true;; esac; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# doublecheck ip of hosts server
if [ -z "`nslookup ${ADBLOCK_DOMAIN} | grep Address | grep ${ADBLOCK_IP}`" ]; then
	echo "security alert: hosts.herndl.org ip does not match, aborting" 1>&2
	exit 1
fi

# check if on android
if command -v getprop >/dev/null 2>&1; then
	ON_ANDROID=1
else
	ON_ANDROID=0
fi

# preparations on android
if [ $ON_ANDROID -eq 1 ]; then
	# remount system dir writeable
	mount -o rw,remount "/system" || { echo "error remounting dir writeable" 1>&2; exit 1; }
fi

# do download with compatible downloader
if command -v curl >/dev/null 2>&1; then
	curl -s "${ADBLOCK_URL}" > "${HOSTS_LOCATION}" || echo "error on downloading via curl" 1>&2
elif command -v wget >/dev/null 2>&1; then
	wget -q "${ADBLOCK_URL}" -O "${HOSTS_LOCATION}" || echo "error on downloading via wget" 1>&2
fi

# finalizing on android
if [ $ON_ANDROID -eq 1 ]; then
	# remount system dir readable
	mount -o ro,remount "/system" || { echo "error remounting dir readable" 1>&2; exit 1; }
fi
