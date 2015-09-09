#!/bin/sh

# inspired by https://goo.gl/YPM1qP

# get absolute directory of script
DIR="$(readlink -f "$0")"
DIR=${DIR%/*}

file_blacklist="$DIR/hosts_blacklist.txt"
file_whitelist="$DIR/hosts_whitelist.txt"
file_result="$DIR/hosts.txt"
file_temp=`mktemp`
file_temp_ipv6="${file_temp}.ipv6"

permissions_result=644

sources_hosts_format=(
	# hpHosts database
	"http://hosts-file.net/ad_servers.txt" # ad/tracking servers
	"http://hosts-file.net/emd.txt" # malware
	"http://hosts-file.net/exp.txt" # exploit
	"http://hosts-file.net/fsa.txt" # fraud
	"http://hosts-file.net/grm.txt" # spam
	"http://hosts-file.net/hfs.txt" # hpHosts forum spammers
	"http://hosts-file.net/hjk.txt" # hijack
	"http://hosts-file.net/mmt.txt" # misleading marketing
	"http://hosts-file.net/pha.txt" # illegal pharmacy
	"http://hosts-file.net/psh.txt" # phishing
	"http://hosts-file.net/wrz.txt" # warez/piracy
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
)

# print argument as message only if verbose is set
echo_verbose() {
	if [ $mode_verbose -eq 1 ]; then
		echo "`date --rfc-2822`: $1"
	fi
}

print_usage() {
	echo "USAGE: <script> [verbose] [check] [clean] [output=<filename>]"
	echo
	echo "verbose: print more info about what is going on"
	echo "check: checks the whitelist and blacklist (whitelisted entries should exist and\
 blacklisted entries should not exist in the uncleaned hosts data)"
	echo "clean: cleanup whitelist and blacklist files ('check' should be run first)"
	echo "ipv6dup: duplicate all the domains with '::0' as prefix instead of '0.0.0.0'"
}

# check all parameters
mode_verbose=0;
mode_check=0;
mode_clean=0;
ipv6dup=0;
for var in $@; do
	if [ "$var" = "verbose" ]; then
		mode_verbose=1
	elif [ "$var" = "check" ]; then
		mode_check=1
	elif [ "$var" = "clean" ]; then
		mode_clean=1
	elif [[ "$var" = "output="* ]]; then
		file_result=${var/output=/}
	elif [[ "$var" = "ipv6dup" ]]; then
		ipv6dup=1
	# unknown or wrong command, print usage
	else
		print_usage
		exit
	fi
done

# read blacklist and whitelist data
echo_verbose "read blacklist and whitelist data from '$file_blacklist' and '$file_whitelist'"
readarray data_blacklist < "$file_blacklist"
readarray data_whitelist < "$file_whitelist"
# clean blacklist and whitelist data
for index in "${!data_blacklist[@]}"; do
	data_blacklist[$index]=`sed -e 's/#.*//g' -e 's/ //g' <<< ${data_blacklist[$index]}`
done
for index in "${!data_whitelist[@]}"; do
	data_whitelist[$index]=`sed -e 's/#.*//g' -e 's/ //g' <<< ${data_whitelist[$index]}`
done

# download all sources in hosts format
for source_hosts_format in "${sources_hosts_format[@]}"; do
	echo_verbose "downloading hosts source '$source_hosts_format' to '$file_temp'"
	curl --location --silent "$source_hosts_format" >> "$file_temp"
done

# download all domain only sources (we're just prepending the ip adress to every line here)
for source_domains_only in "${sources_domains_only[@]}"; do
	echo_verbose "downloading domain only source '$source_domains_only' to '$file_temp'"
	curl --location --silent "$source_domains_only" | sed -e 's/^/0.0.0.0 /' >> "$file_temp"
done

echo_verbose "cleaning up '$file_temp'"
# Remove MS-DOS carriage returns
sed -i -e 's/\r//g' "$file_temp"
# Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the resolver to fail
sed -i -e 's/127.0.0.1/0.0.0.0/g' "$file_temp"
# Remove all comments
sed -i -e 's/#.*//g' "$file_temp"
# Strip trailing spaces and tabs
sed -i -e 's/[ \t]*$//g' "$file_temp"
# Replace tabs with a space
sed -i -e 's/\t/ /g' "$file_temp"
# Replace strange space character
sed -i -e 's/ ﻿/ /g' "$file_temp"
# Replace multiple spaces with one space
sed -i -e 's/ \{2,\}/ /g' "$file_temp"
# Remove lines that do not start with "0.0.0.0"
sed -i -e '/^0.0.0.0/!d' "$file_temp"
# Remove localhost lines
sed -i -r -e '/^0\.0\.0\.0 local(host)*(.localdomain)*$/d' "$file_temp"
# Remove lines that start correct but have no or empty domain
sed -i -e '/^0\.0\.0\.0 \{0,\}$/d' "$file_temp"
# Remove lines with invalid domains (domains must start with an alphanumeric character)
sed -i -e '/^0\.0\.0\.0 [^a-zA-Z0-9]/d' "$file_temp"

# check mode (checks entries of the white- & blacklist)
# clean mode (remove whitelist entries that do not exist in the hosts file and remove blacklist
# entries that do already exist in the hosts file)
if [ $mode_check -eq 1 ] || [ $mode_clean -eq 1 ]; then
	for data_whitelist_entry in "${data_whitelist[@]}"; do
		echo_verbose "check if '$data_whitelist_entry' is not existing in '$file_temp'"
		if [ -z "`grep $data_whitelist_entry "$file_temp"`" ]; then
			if [ $mode_clean -eq 1 ]; then
				echo "removing entry '$data_whitelist_entry' from the whitelist"
				sed -i -e "/$data_whitelist_entry/d" "$file_whitelist"
			else
				echo "whitelist entry '$data_whitelist_entry' is not existing in '$file_temp'"
			fi
		fi
	done
	for data_blacklist_entry in "${data_blacklist[@]}"; do
		echo_verbose "check if '$data_blacklist_entry' is existing in '$file_temp'"
		if [ -n "`grep $data_blacklist_entry "$file_temp"`" ]; then
			if [ $mode_clean -eq 1 ]; then
				echo "removing entry '$data_blacklist_entry' from the blacklist"
				sed -i -e "/$data_blacklist_entry/d" "$file_blacklist"
			else
				echo "blacklist entry '$data_blacklist_entry' is existing in '$file_temp'"
			fi
		fi
	done
fi

# remove all whitelisted entries from hosts.txt file
echo_verbose "removing all whitelisted entries"
for data_whitelist_entry in "${data_whitelist[@]}"; do
	sed -i -e "/ $data_whitelist_entry/d" "$file_temp"
done

# add all blacklisted entries to hosts.txt file
echo_verbose "adding all blacklisted entries"
for data_blacklist_entry in "${data_blacklist[@]}"; do
	echo "0.0.0.0 $data_blacklist_entry" >> "$file_temp"
done

# sort file entries and remove multiple occuring entries
echo_verbose "sort file entries and remove multiple occuring entries"
sort -u -o "$file_temp" "$file_temp"

# duplicate data for IPv6 (e.g. dnsmasq needs such entries to block IPv6 hosts!)
if [ $ipv6dup -eq 1 ]; then
	echo_verbose "duplicate data for IPv6 in temp file '$file_temp_ipv6'"
	cp "$file_temp" "$file_temp_ipv6"
	sed -i -e 's/0.0.0.0/::0/g' "$file_temp_ipv6"
	cat "$file_temp_ipv6" >> "$file_temp"
	rm -f "$file_temp_ipv6"
fi

# generate and write file header
echo_verbose "generating and writing file header"
data_header="# clean merged adblocking-hosts file\n\
# build date: `date --rfc-2822`\n\
# build server: `hostname`\n\
# more infos: https://github.com/monojp/hosts_merge\n\
\n\
127.0.0.1 localhost.localdomain localhost\n\
::1 localhost.localdomain localhost\n"
sed -i "1i${data_header}" "$file_temp"

# rotate in place
echo_verbose "move temp file '$file_temp' to '$file_result'"
mv -f "$file_temp" "$file_result"

# fixup permissions (we don't want that limited temp perms)
echo_verbose "chmod '$file_result' to '$permissions_result'"
chmod $permissions_result "$file_result"
