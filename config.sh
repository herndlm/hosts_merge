#!/bin/bash

# get absolute directory of script
DIR="$(readlink -f "$0")"
DIR=${DIR%/*}

export file_blacklist="$DIR/hosts_blacklist.txt"
export file_whitelist="$DIR/hosts_whitelist.txt"
export file_result="$DIR/hosts.txt"

export permissions_result=644

export FILE_LOG="/tmp/hosts_merge.log"

export sources_hosts_format=(
	# global common
	"http://winhelp2002.mvps.org/hosts.txt"
	"https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts"
	"https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts_browser"
	"https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext&useip=0.0.0.0"
	"https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
	"https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts"
	"https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt"
	"https://raw.githubusercontent.com/lightswitch05/hosts/master/ads-and-tracking-extended.txt"
	"https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
	"https://someonewhocares.org/hosts/zero/hosts"
	"https://sysctl.org/cameleon/hosts"
	"https://www.malwaredomainlist.com/hostslist/hosts.txt"
	"https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
	# OCSP / CRL
	"https://raw.githubusercontent.com/ScottHelme/revocation-endpoints/master/ocsp.txt"
	"https://raw.githubusercontent.com/ScottHelme/revocation-endpoints/master/crl.txt"
	# Windows 10 Anti Spy
	"https://www.encrypt-the-planet.com/downloads/hosts"
	# Blacklist
	"https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
	# Ultimate Hosts Blacklist
	"https://hosts.ubuntu101.co.za/hosts"
	# DataMaster-Android-AdBlock-Hosts
	"https://raw.githubusercontent.com/DataMaster-2501/DataMaster-Android-AdBlock-Hosts/master/hosts"
	# NoCoin Filter List
	"https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt"
	# WindowsSpyBlocker - Hosts spy rules
	"https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
)

export sources_domains_only=(
	# abuse / tracking lists (beware of false positives)
	"https://malwaredomains.usu.edu/immortal_domains.txt"
	"https://malwaredomains.usu.edu/justdomains"
	#"https://isc.sans.edu/feeds/suspiciousdomains_Low.txt"
	#"https://www.blocklist.de/downloads/urls/95.211.0.112-only-domains.txt"
	#"https://www.blocklist.de/downloads/urls/squarespace.com-only-subdomains.txt"
	#"http://malc0de.com/bl/BOOT"
	# disconnect.me
	"https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
	# smart tvs
	"https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
	# Spam404
	"https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
	# NoTracking
	"https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"
	# Personal Blocklist by WaLLy3K
	"https://v.firebog.net/hosts/static/w3kbl.txt"
)
