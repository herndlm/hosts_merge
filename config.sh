#!/bin/sh

# get absolute directory of script
DIR="$(readlink -f "$0")"
DIR=${DIR%/*}

file_blacklist="$DIR/hosts_blacklist.txt"
file_whitelist="$DIR/hosts_whitelist.txt"
file_result="$DIR/hosts.txt"

permissions_result=644

FILE_LOG="/tmp/hosts_merge.log"

sources_hosts_format=(
	# global common
	"https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext&useip=0.0.0.0"
	"http://winhelp2002.mvps.org/hosts.txt"
	"https://someonewhocares.org/hosts/zero/hosts"
	"http://www.malwaredomainlist.com/hostslist/hosts.txt"
	"https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt"
	"https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
	"https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
	"https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
	"https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts"
	"https://raw.githubusercontent.com/lightswitch05/hosts/master/ads-and-tracking-extended.txt"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
	"https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"http://sysctl.org/cameleon/hosts.win"
	# abuse / tracking lists (beware of false positives)
	"https://zeustracker.abuse.ch/blocklist.php?download=hostfile"
)

sources_domains_only=(
	# abuse / tracking lists (beware of false positives)
	#"https://malwaredomains.usu.edu/justdomains"
	#"https://isc.sans.edu/feeds/suspiciousdomains_Low.txt"
	#"https://www.blocklist.de/downloads/urls/95.211.0.112-only-domains.txt"
	#"https://www.blocklist.de/downloads/urls/squarespace.com-only-subdomains.txt"
	#"http://malc0de.com/bl/BOOT"
	"https://www.malwaredomainlist.com/hostslist/hosts.txt"
	# disconnect.me
	"https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
	"https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
)
