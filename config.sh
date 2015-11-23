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
	# hpHosts database (unfortunately way too big for slow systems)
	#"http://hosts-file.net/ad_servers.txt" # ad/tracking servers
	#"http://hosts-file.net/emd.txt" # malware
	#"http://hosts-file.net/exp.txt" # exploit
	#"http://hosts-file.net/fsa.txt" # fraud
	#"http://hosts-file.net/grm.txt" # spam
	#"http://hosts-file.net/hfs.txt" # hpHosts forum spammers
	#"http://hosts-file.net/hjk.txt" # hijack
	#"http://hosts-file.net/mmt.txt" # misleading marketing
	#"http://hosts-file.net/pha.txt" # illegal pharmacy
	#"http://hosts-file.net/psh.txt" # phishing
	#"http://hosts-file.net/wrz.txt" # warez/piracy
	# global common
	"http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts"
	"http://winhelp2002.mvps.org/hosts.txt"
	"http://someonewhocares.org/hosts/hosts"
	# japanese
	"https://sites.google.com/site/cosmonoteshosts/hosts_for_Windows8.txt?attredirects=0"
	# abuse / tracking lists
	"https://zeustracker.abuse.ch/blocklist.php?download=hostfile"
	"http://sysctl.org/cameleon/hosts.win"
)

sources_domains_only=(
	# abuse / tracking lists
	"http://mirror2.malwaredomains.com/files/justdomains"
	"https://isc.sans.edu/feeds/suspiciousdomains_Low.txt"
	# disconnect.me
        "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
        "https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt"
        "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
        "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
)
