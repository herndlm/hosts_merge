#!/bin/sh

# inspired by https://goo.gl/YPM1qP

# get absolute directory of script
DIR="$(readlink -f "$0")"
DIR=${DIR%/*}

file_blacklist="$DIR/hosts_blacklist.txt"
file_whitelist="$DIR/hosts_whitelist.txt"
file_result="$DIR/hosts.txt"
file_ipv6="${file_result}.ipv6"

sources=(
	# global common
	"http://hosts-file.net/ad_servers.txt"
	"http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
	"http://winhelp2002.mvps.org/hosts.txt"
	"http://someonewhocares.org/hosts/hosts"
	# abuse / tracking lists (may have many false positives)
	#"http://mirror2.malwaredomains.com/files/BOOT" # not a valid hosts format
	#"https://zeustracker.abuse.ch/blocklist.php?download=hostfile"
	#"http://sysctl.org/cameleon/hosts.win"
	#"http://support.it-mate.co.uk/downloads/HOSTS.txt" # too big
	# japanese special
	"https://sites.google.com/site/cosmonoteshosts/hosts_for_Windows8.txt?attredirects=0"
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
}

# check all parameters
mode_verbose=0;
mode_check=0;
mode_clean=0;
for var in $@; do
	if [ "$var" = "verbose" ]; then
		mode_verbose=1
	elif [ "$var" = "check" ]; then
		mode_check=1
	elif [ "$var" = "clean" ]; then
		mode_clean=1
	elif [[ "$var" = "output="* ]]; then
		file_result=${var/output=/}
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

# truncate result file
echo_verbose "truncate file '$file_result'"
: > "$file_result"

# download all sources
for source in "${sources[@]}"; do
	echo_verbose "downloading '$source' to '$file_result'"
	curl --location --silent "$source" >> "$file_result"
done

echo_verbose "cleaning up '$file_result'"
# Remove MS-DOS carriage returns
sed -i -e 's/\r//g' "$file_result"
# Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the resolver to fail
sed -i -e 's/127.0.0.1/0.0.0.0/g' "$file_result"
# Delete any lines containing the word localhost
sed -i -e '/localhost/d' "$file_result"
# Remove all comments
sed -i -e 's/#.*//g' "$file_result"
# Replace tabs with a space
sed -i -e 's/\t/ /g' "$file_result"
# Replace multiple spaces with one space
sed -i -e 's/ \{2,\}/ /g' "$file_result"
# Remove lines that do not start with "0.0.0.0"
sed -i -e '/^0.0.0.0/!d' "$file_result"

# check mode (checks entries of the white- & blacklist)
# clean mode (remove whitelist entries that do not exist in the hosts file and remove blacklist
# entries that do already exist in the hosts file)
if [ $mode_check -eq 1 ] || [ $mode_clean -eq 1 ]; then
	for data_whitelist_entry in "${data_whitelist[@]}"; do
		echo_verbose "check if '$data_whitelist_entry' is not existing in '$file_result'"
		if [ -z "`grep $data_whitelist_entry "$file_result"`" ]; then
			if [ $mode_clean -eq 1 ]; then
				echo "removing entry '$data_whitelist_entry' from the whitelist"
				sed -i -e "/$data_whitelist_entry/d" "$file_whitelist"
			else
				echo "whitelist entry '$data_whitelist_entry' is not existing in '$file_result'"
			fi
		fi
	done
	for data_blacklist_entry in "${data_blacklist[@]}"; do
		echo_verbose "check if '$data_blacklist_entry' is existing in '$file_result'"
		if [ -n "`grep $data_blacklist_entry "$file_result"`" ]; then
			if [ $mode_clean -eq 1 ]; then
				echo "removing entry '$data_blacklist_entry' from the blacklist"
				sed -i -e "/$data_blacklist_entry/d" "$file_blacklist"
			else
				echo "blacklist entry '$data_blacklist_entry' is existing in '$file_result'"
			fi
		fi
	done
fi

# remove all whitelisted entries from hosts.txt file
echo_verbose "removing all whitelisted entries"
for data_whitelist_entry in "${data_whitelist[@]}"; do
	sed -i -e "/ $data_whitelist_entry/d" "$file_result"
done

# add all blacklisted entries to hosts.txt file
echo_verbose "adding all blacklisted entries"
for data_blacklist_entry in "${data_blacklist[@]}"; do
	echo "0.0.0.0 $data_blacklist_entry" >> "$file_result"
done

# sort file entries and remove multiple occuring entries
echo_verbose "sort file entries and remove multiple occuring entries"
sort -u -o "$file_result" "$file_result"

# duplicate data for IPv6 (e.g. dnsmasq needs such entries to block IPv6 hosts!)
echo_verbose "duplicate data for IPv6"
cp "$file_result" "$file_ipv6"
sed -i -e 's/0.0.0.0/::0/g' "$file_ipv6"
cat "$file_ipv6" >> "$file_result"
rm -f "$file_ipv6"

# generate and write file header
echo_verbose "generating and writing file header"
data_header="# clean merged adblocking-hosts file\n\
# source: hosts.herndl.org\n\
# build date: `date --rfc-2822`\n\
\n\
127.0.0.1 localhost.localdomain localhost\n\
::1 localhost.localdomain localhost\n"
sed -i "1i${data_header}" "$file_result"
