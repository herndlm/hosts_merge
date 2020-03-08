#!/bin/bash

# https://github.com/monojp/hosts_merge
# inspired by https://www.kubuntuforums.net/showthread.php/56419-Script-to-automate-building-an-adblocking-hosts-file

# get absolute directory of script
DIR="$(readlink -f "$0")"
DIR=${DIR%/*}

CURL_RETRY_NUM=5
CURL_TIMEOUT=300

file_blacklist=""
file_whitelist=""
file_result=""
permissions_result=0
FILE_LOG=""
sources_hosts_format=()
sources_domains_only=()

# include user config
# shellcheck source=config.sh
source "${DIR}/config.sh"

# create / define temp files
file_temp=$(mktemp)
file_temp_ipv6="${file_temp}.ipv6"

# cleanup if user presses CTRL-C
cleanup() {
  log "cleaning up temp files"
  rm "${file_temp}" >/dev/null 2>&1
  rm "${file_temp_ipv6}" >/dev/null 2>&1
  exit 0
}
trap cleanup INT SIGHUP SIGINT SIGTERM

# log to stdout if verbose flag set and/or to file if file variable note empty
log() {
  # add date to message
  message="$(date --rfc-3339='seconds') $1"
  # log to file if variable is not empty
  if [ -n "$FILE_LOG" ]; then
    echo -e "${message}" >> "$FILE_LOG"
  fi
  # print argument as message if verbose is set
  if [ "${mode_verbose}" -eq 1 ]; then
    echo -e "${message}"
  fi
}

# function that outputs logs, outputs to stderr and exits
log_exit() {
  log "$1"
  cleanup
  echo >&2 "$1"
  exit 1
}

# return md5sum (not file name) of file $1
md5file() {
  md5sum "$1" | awk '{print $1}'
}

# checks if the domain resolves via DNS
domain_resolves() {
  output="$(dig "$1" +short)"
  # return OK if dig failes to avoid deleting domains when there are dns failures
  # shellcheck disable=SC2181
  if [ "$?" -ne "0" ]; then
    return 0
  fi

  # domain resolves if dig outputs anything
  if [ -n "${output}" ]; then
    return 0
  fi

  return 1
}

# check dependencies
command -v curl >/dev/null 2>&1 || log_exit "missing dependency: curl"
command -v grep >/dev/null 2>&1 || log_exit "missing dependency: grep"
command -v sed >/dev/null 2>&1 || log_exit "missing dependency: sed"

print_usage() {
  echo "USAGE: <script> [verbose] [check] [clean] [ipv6dup] [output=<filename>]"
  echo
  echo "verbose: print more info about what is going on"
  echo "check: checks the whitelist and blacklist (whitelisted entries should exist and blacklisted entries should not exist in the uncleaned hosts data), furthermore non-resolving domains from the blacklist are reported"
  echo "clean: cleanup whitelist and blacklist files (fixes the issues reported by check)"
  echo "ipv6dup: duplicate all the domains with '::0' as prefix instead of '0.0.0.0'"
}

# check all parameters
mode_verbose=0
mode_check=0
mode_clean=0
ipv6dup=0
for var in "$@"; do
  if [ "${var}" = "verbose" ]; then
    mode_verbose=1
  elif [ "${var}" = "check" ]; then
    mode_check=1
  elif [ "${var}" = "clean" ]; then
    mode_clean=1
  elif [[ "${var}" == "output="* ]]; then
    file_result=${var/output=/}
  elif [[ "${var}" == "ipv6dup" ]]; then
    ipv6dup=1
  # unknown or wrong command, print usage
  else
    print_usage
    exit
  fi
done

# read blacklist and whitelist data
log "read blacklist and whitelist data from '$file_blacklist' and '$file_whitelist'"
data_blacklist=()
readarray data_blacklist <"${file_blacklist}" || log_exit "error on reading blacklist"
data_whitelist=()
readarray data_whitelist <"${file_whitelist}" || log_exit "error on reading whitelist"
# clean blacklist and whitelist data
log "clean blacklist and whitelist data"
for index in "${!data_blacklist[@]}"; do
  data_blacklist[$index]=$(sed -e 's/#.*//g' -e 's/ //g' <<<"${data_blacklist[$index]}")
done
for index in "${!data_whitelist[@]}"; do
  data_whitelist[$index]=$(sed -e 's/#.*//g' -e 's/ //g' <<<"${data_whitelist[$index]}")
done

# download all sources in hosts format
for source_hosts_format in "${sources_hosts_format[@]}"; do
  log "downloading hosts source '$source_hosts_format' to '$file_temp'"
  curl --location -sS --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} \
    --retry ${CURL_RETRY_NUM} "${source_hosts_format}" >> "${file_temp}" ||
    log_exit "error downloading file '${source_hosts_format}'"
done

# download all domain only sources (we're cleaning the lines and prepending ip adresses)
for source_domains_only in "${sources_domains_only[@]}"; do
  log "downloading domain only source '${source_domains_only}' to '${file_temp}'"
  curl --location -sS --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} \
    --retry ${CURL_RETRY_NUM} "${source_domains_only}" | sed -e 's/^PRIMARY//g' |
    sed -e 's/blockeddomain\.hosts$//g' | sed -e 's/^/0.0.0.0 /' >> "${file_temp}" ||
    log_exit "error downloading file 'source_domains_only'"
done

log "cleaning up '${file_temp}'"
# Remove MS-DOS carriage returns
sed -i -e 's/\r//g' "${file_temp}" || log_exit "error on cleanup"
# Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the resolver to fail
sed -i -e 's/127.0.0.1/0.0.0.0/g' "${file_temp}" || log_exit "error on cleanup"
# Remove all comments
sed -i -e 's/#.*//g' "${file_temp}" || log_exit "error on cleanup"
# Strip trailing spaces and tabs
sed -i -e 's/[ \t]*$//g' "${file_temp}" || log_exit "error on cleanup"
# Replace tabs with a space
sed -i -e 's/\t/ /g' "${file_temp}" || log_exit "error on cleanup"
# Remove lines containing invalid characters
sed -i -e '/[^a-zA-Z0-9\t\. _-]/d' "${file_temp}" || log_exit "error on cleanup"
# Replace multiple spaces with one space
sed -i -e 's/ \{2,\}/ /g' "${file_temp}" || log_exit "error on cleanup"
# Remove lines that do not start with "0.0.0.0"
sed -i -e '/^0.0.0.0/!d' "${file_temp}" || log_exit "error on cleanup"
# Remove localhost lines
sed -i -r -e '/^0\.0\.0\.0 local(host)*(.localdomain)*$/d' "${file_temp}" ||
  log_exit "error on cleanup"
# Remove lines that start correct but have no or empty domain
sed -i -e '/^0\.0\.0\.0 \{0,\}$/d' "${file_temp}" || log_exit "error on cleanup"
# Remove lines with invalid domains (domains must start with an alphanumeric character)
sed -i -e '/^0\.0\.0\.0 [^a-zA-Z0-9]/d' "${file_temp}" || log_exit "error on cleanup"

# check mode (checks entries of the white- & blacklist)
# clean mode (remove whitelist entries that do not exist in the hosts file and remove blacklist
# entries that do already exist in the hosts file)
if [ ${mode_check} -eq 1 ] || [ ${mode_clean} -eq 1 ]; then
  # whitelist
  count=${#data_whitelist[@]}
  counter=0
  for data_whitelist_entry in "${data_whitelist[@]}"; do
    counter=$((counter + 1))
    if [ -z "${data_whitelist_entry}" ]; then
      continue
    fi

    if grep -q "^0.0.0.0 ${data_whitelist_entry}$" "${file_temp}"; then
      # entry that is not blocked any more
      if [ ${mode_clean} -eq 1 ]; then
        echo "${counter}/${count} removing entry '${data_whitelist_entry}' from the whitelist"
        sed -i -e "/${data_whitelist_entry}/d" "${file_whitelist}" || log_exit "error on removing whitelist entry"
      else
        echo "${counter}/${count} whitelist entry '${data_whitelist_entry}' is not existing in '${file_temp}'"
      fi
    elif ! domain_resolves "${data_whitelist_entry}"; then
      # entry that is not resolving any more
      if [ ${mode_clean} -eq 1 ]; then
        echo "${counter}/${count} removing non-resolving entry '${data_whitelist_entry}' from the whitelist"
        sed -i -e "/${data_whitelist_entry}/d" "${file_whitelist}" || log_exit "error on removing whitelist entry"
      else
        echo "${counter}/${count} whitelist entry '${data_whitelist_entry}' is not resolving"
      fi
    fi
  done
  # blacklist
  count=${#data_blacklist[@]}
  counter=0
  for data_blacklist_entry in "${data_blacklist[@]}"; do
    counter=$((counter + 1))
    if [ -z "${data_blacklist_entry}" ]; then
      continue
    fi

    if grep -q "^0.0.0.0 ${data_blacklist_entry}$" "${file_temp}"; then
      # entry that is already blocked
      if [ ${mode_clean} -eq 1 ]; then
        echo "${counter}/${count} removing entry '${data_blacklist_entry}' from the blacklist"
        sed -i -e "/${data_blacklist_entry}/d" "${file_blacklist}" || log_exit "error on removing blacklist entry"
      else
        echo "${counter}/${count} blacklist entry '${data_blacklist_entry}' is existing in '${file_temp}'"
      fi
    elif ! domain_resolves "${data_blacklist_entry}"; then
      # entry that is not resolving any more
      if [ ${mode_clean} -eq 1 ]; then
        echo "${counter}/${count} removing non-resolving entry '${data_blacklist_entry}' from the blacklist"
        sed -i -e "/${data_blacklist_entry}/d" "${file_blacklist}" || log_exit "error on removing blacklist entry"
      else
        echo "${counter}/${count} blacklist entry '${data_blacklist_entry}' is not resolving"
      fi
    fi
  done
fi

# remove all whitelisted entries from hosts.txt file
log "removing all whitelisted entries"
for data_whitelist_entry in "${data_whitelist[@]}"; do
  if [ -n "${data_whitelist_entry}" ]; then
    sed -i -e "/ ${data_whitelist_entry}/d" "${file_temp}" || log_exit "error on removing whitelisted entry"
  fi
done

# add all blacklisted entries to hosts.txt file
log "adding all blacklisted entries"
for data_blacklist_entry in "${data_blacklist[@]}"; do
  if [ -n "${data_blacklist_entry}" ]; then
    echo "0.0.0.0 ${data_blacklist_entry}" >> "${file_temp}" || log_exit "error on adding blacklisted entry"
  fi
done

# sort file entries and remove multiple occuring entries
log "sort file entries and remove multiple occuring entries"
sort -u -o "${file_temp}" "${file_temp}" || log_exit "error on sorting"

# duplicate data for IPv6 (e.g. dnsmasq needs such entries to block IPv6 hosts)
if [ ${ipv6dup} -eq 1 ]; then
  log "duplicate data for IPv6 in temp file '${file_temp_ipv6}'"
  cp "${file_temp}" "${file_temp_ipv6}" || log_exit "error on copying '${file_temp}' to '${file_temp_ipv6}'"
  sed -i -e 's/0.0.0.0/::0/g' "${file_temp_ipv6}" || log_exit "error on IPv6 replacement via sed"
  cat "${file_temp_ipv6}" >> "${file_temp}" || log_exit "error on IPv6 replacement via cat"
  rm -f "${file_temp_ipv6}" || log_exit "error on deleting '${file_temp_ipv6}'"
fi

# generate and write file header
log "generating and writing file header"
data_header="# clean merged adblocking-hosts file\n\
# build server: $(hostname)\n\
# more infos: https://github.com/monojp/hosts_merge\n\
\n\
127.0.0.1 localhost\n\
::1 localhost\n"
sed -i "1i${data_header}" "${file_temp}" || log_exit "error on writing file headers"

# rotate in place and fix permissions if md5sum old - new is different, otherwise we're done
if [ "$(md5file "${file_result}")" != "$(md5file "${file_temp}")" ]; then
  # rotate in place
  log "move temp file '$file_temp' to '$file_result'"
  mv -f "${file_temp}" "${file_result}" || log_exit "error on moving '${file_temp}' to '${file_result}'"

  # fixup permissions (we don't want that limited temp perms)
  log "chmod '${file_result}' to '${permissions_result}'"
  chmod ${permissions_result} "${file_result}" || log_exit "error on chmod on '${file_result}'"
else
  log "no changes, skip rotating in place"
fi

cleanup
