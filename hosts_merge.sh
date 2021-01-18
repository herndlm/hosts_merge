#!/bin/bash

# https://github.com/monojp/hosts_merge
# inspired by https://www.kubuntuforums.net/showthread.php/56419-Script-to-automate-building-an-adblocking-hosts-file

set -euo pipefail
IFS=$'\n\t'

readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

readonly OS_NAME="$(uname -s)"
if [[ $OS_NAME == "Darwin" ]]; then
  readonly SED_COMMAND="gsed"
elif [[ $OS_NAME == "Linux" ]]; then
  readonly SED_COMMAND="sed"
else
  echo >&2 "OS ${OS_NAME} is not supported"
  exit 1
fi

CURL_RETRY_NUM=5
CURL_TIMEOUT=300

readonly FILE_BLACKLIST="${DIR}/hosts_blacklist.txt"
readonly FILE_WHITELIST="${DIR}/hosts_whitelist.txt"
readonly FILE_RESULT="${DIR}/hosts.txt"

readonly PERMISSIONS_RESULT=644

readonly FILE_LOG="/tmp/hosts_merge.log"

readonly SOURCES_HOST_FORMAT=(
  # MVPS HOSTS
  "https://winhelp2002.mvps.org/hosts.txt"
  # CoinBlockerLists
  "https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts"
  "https://gitlab.com/ZeroDot1/CoinBlockerLists/raw/master/hosts_browser"
  # pgl@yoyo.org
  "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext&useip=0.0.0.0"
  # AdAway
  "https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt"
  # FadeMind
  "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
  "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
  "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
  "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
  "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
  # StevenBlack
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/data/StevenBlack/hosts"
  # Bad Boys Hosts
  "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
  # Dan Pollock hosts
  "https://someonewhocares.org/hosts/zero/hosts"
  # CAMELEON
  "https://sysctl.org/cameleon/hosts"
  # MalwareDomainList.com Hosts List
  "https://www.malwaredomainlist.com/hostslist/hosts.txt"
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
  # First-party trackers host list
  "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
  # abuse.ch URLhaus Host file
  "https://urlhaus.abuse.ch/downloads/hostfile/"
  # DigitalSite Threat-Intel
  "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
  # Phishing Army
  "https://phishing.army/download/phishing_army_blocklist_extended.txt"
  # GoodByeAds
  "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt"
  "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Samsung-AdBlock.txt"
  "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Spotify-AdBlock.txt"
  "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Xiaomi-Extension.txt"
  "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
  # NoTracking
  "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"
)

readonly SOURCES_DOMAINS_ONLY=(
  # malwaredomains
  "https://malwaredomains.usu.edu/immortal_domains.txt"
  "https://malwaredomains.usu.edu/justdomains"
  # disconnect.me
  "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
  "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
  "https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt"
  "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
  # Perflyst's Smart-TV Blocklist for Pi-hole
  "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
  # Spam404
  "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
  # Personal Blocklist by WaLLy3K
  "https://v.firebog.net/hosts/static/w3kbl.txt"
)

readonly FILE_TEMP=$(mktemp)
readonly FILE_TEMP_IPV6="${FILE_TEMP}.ipv6"

# cleanup if user presses CTRL-C
cleanup() {
  log "cleaning up temp files"

  if [ -f "${FILE_TEMP}" ]; then
    rm "${FILE_TEMP}"
  fi

  if [ -f "${FILE_TEMP_IPV6}" ]; then
    rm "${FILE_TEMP_IPV6}"
  fi

  exit 0
}
trap cleanup INT SIGHUP SIGINT SIGTERM

# log to stdout if verbose flag set and/or to file if file variable note empty
log() {
  # add date to message
  local -r message="$(date) $1"
  # log to file if variable is not empty
  if [ -n "$FILE_LOG" ]; then
    echo -e "${message}" >>"$FILE_LOG"
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

# checks if the domain resolves via DNS
domain_resolves() {
  local -r output="$(dig "$1" +short @46.182.19.48)"
  # return OK if dig fails to avoid deleting domains when there are dns failures
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

print_usage() {
  echo "USAGE: <script> [verbose] [check] [clean] [ipv6dup] [output=<filename>]"
  echo
  echo "verbose: print more info about what is going on"
  echo "check: checks the whitelist and blacklist (whitelisted entries should exist and blacklisted entries should not exist in the uncleaned hosts data), furthermore non-resolving domains from the blacklist are reported"
  echo "clean: cleanup whitelist and blacklist files (fixes the issues reported by check)"
  echo "ipv6dup: duplicate all the domains with '::0' as IP instead of '0.0.0.0'"
}

check_dependencies() {
  command -v curl >/dev/null 2>&1 || log_exit "missing dependency: curl"
  command -v dig >/dev/null 2>&1 || log_exit "missing dependency: dig"
  command -v grep >/dev/null 2>&1 || log_exit "missing dependency: grep"
  command -v "${SED_COMMAND}" >/dev/null 2>&1 || log_exit "missing dependency: ${SED_COMMAND}"
}

main() {
  check_dependencies

  # read blacklist and whitelist data
  log "read blacklist and whitelist data from '$FILE_BLACKLIST' and '$FILE_WHITELIST'"
  local data_blacklist=()
  readarray data_blacklist <"${FILE_BLACKLIST}"
  local data_whitelist=()
  readarray data_whitelist <"${FILE_WHITELIST}"
  # clean blacklist and whitelist data
  log "clean blacklist and whitelist data"
  for index in "${!data_blacklist[@]}"; do
    data_blacklist[$index]=$("${SED_COMMAND}" -e 's/#.*//g' -e 's/ //g' <<<"${data_blacklist[$index]}")
  done
  readonly data_blacklist
  for index in "${!data_whitelist[@]}"; do
    data_whitelist[$index]=$("${SED_COMMAND}" -e 's/#.*//g' -e 's/ //g' <<<"${data_whitelist[$index]}")
  done
  readonly data_whitelist

  # download all sources in hosts format
  for source_hosts_format in "${SOURCES_HOST_FORMAT[@]}"; do
    log "downloading hosts source '$source_hosts_format' to '$FILE_TEMP'"
    curl --location -sS --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} \
      --fail --retry ${CURL_RETRY_NUM} "${source_hosts_format}" >>"${FILE_TEMP}"
  done

# download all domain only sources (we're cleaning the lines and prepending ip adresses)
for source_domains_only in "${SOURCES_DOMAINS_ONLY[@]}"; do
  log "downloading domain only source '${source_domains_only}' to '${FILE_TEMP}'"
  curl --location -sS --connect-timeout ${CURL_TIMEOUT} --max-time ${CURL_TIMEOUT} \
    --fail --retry ${CURL_RETRY_NUM} "${source_domains_only}" |
    grep -v '^#' |
    "${SED_COMMAND}" -e 's/^/0.0.0.0 /' >>"${FILE_TEMP}"
done

  log "cleaning up '${FILE_TEMP}'"
  # Remove MS-DOS carriage returns
  "${SED_COMMAND}" -i -e 's/\r//g' "${FILE_TEMP}"
  # Replace 127.0.0.1 with 0.0.0.0 because then we don't have to wait for the resolver to fail
  "${SED_COMMAND}" -i -e 's/127.0.0.1/0.0.0.0/g' "${FILE_TEMP}"
  # Remove all comments
  "${SED_COMMAND}" -i -e 's/#.*//g' "${FILE_TEMP}"
  # Strip trailing spaces and tabs
  "${SED_COMMAND}" -i -e 's/[ \t]*$//g' "${FILE_TEMP}"
  # Replace tabs with a space
  "${SED_COMMAND}" -i -e 's/\t/ /g' "${FILE_TEMP}"
  # Remove lines containing invalid characters
  "${SED_COMMAND}" -i -e '/[^a-zA-Z0-9\t\. _-]/d' "${FILE_TEMP}"
  # Replace multiple spaces with one space
  "${SED_COMMAND}" -i -e 's/ \{2,\}/ /g' "${FILE_TEMP}"
  # Remove lines that do not start with "0.0.0.0"
  "${SED_COMMAND}" -i -e '/^0.0.0.0/!d' "${FILE_TEMP}"
  # Remove localhost lines
  "${SED_COMMAND}" -i -r -e '/^0\.0\.0\.0 local(host)*(.localdomain)*$/d' "${FILE_TEMP}"
  # Remove lines that start correct but have no or empty domain
  "${SED_COMMAND}" -i -e '/^0\.0\.0\.0 \{0,\}$/d' "${FILE_TEMP}"
  # Remove lines with invalid domains (domains must start with an alphanumeric character)
  "${SED_COMMAND}" -i -e '/^0\.0\.0\.0 [^a-zA-Z0-9]/d' "${FILE_TEMP}"

  # check mode (checks entries of the white- & blacklist)
  # clean mode (remove whitelist entries that do not exist in the hosts file and remove blacklist
  # entries that do already exist in the hosts file)
  if [ "${mode_check}" -eq 1 ] || [ "${mode_clean}" -eq 1 ]; then
    # whitelist
    count=${#data_whitelist[@]}
    counter=0
    for data_whitelist_entry in "${data_whitelist[@]}"; do
      counter=$((counter + 1))
      if [ -z "${data_whitelist_entry}" ]; then
        continue
      fi

      if grep -q "^0.0.0.0 ${data_whitelist_entry}$" "${FILE_TEMP}"; then
        # entry that is not blocked any more
        if [ "${mode_clean}" -eq 1 ]; then
          echo "${counter}/${count} removing entry '${data_whitelist_entry}' from the whitelist"
          "${SED_COMMAND}" -i -e "/${data_whitelist_entry}/d" "${FILE_WHITELIST}"
        else
          echo "${counter}/${count} whitelist entry '${data_whitelist_entry}' is not existing in '${FILE_TEMP}'"
        fi
      elif ! domain_resolves "${data_whitelist_entry}"; then
        # entry that is not resolving any more
        if [ "${mode_clean}" -eq 1 ]; then
          echo "${counter}/${count} removing non-resolving entry '${data_whitelist_entry}' from the whitelist"
          "${SED_COMMAND}" -i -e "/${data_whitelist_entry}/d" "${FILE_WHITELIST}"
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

      if grep -q "^0.0.0.0 ${data_blacklist_entry}$" "${FILE_TEMP}"; then
        # entry that is already blocked
        if [ "${mode_clean}" -eq 1 ]; then
          echo "${counter}/${count} removing entry '${data_blacklist_entry}' from the blacklist"
          "${SED_COMMAND}" -i -e "/${data_blacklist_entry}/d" "${FILE_BLACKLIST}"
        else
          echo "${counter}/${count} blacklist entry '${data_blacklist_entry}' is existing in '${FILE_TEMP}'"
        fi
      elif ! domain_resolves "${data_blacklist_entry}"; then
        # entry that is not resolving any more
        if [ "${mode_clean}" -eq 1 ]; then
          echo "${counter}/${count} removing non-resolving entry '${data_blacklist_entry}' from the blacklist"
          "${SED_COMMAND}" -i -e "/${data_blacklist_entry}/d" "${FILE_BLACKLIST}"
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
      "${SED_COMMAND}" -i -e "/ ${data_whitelist_entry}/d" "${FILE_TEMP}"
    fi
  done

  # add all blacklisted entries to hosts.txt file
  log "adding all blacklisted entries"
  for data_blacklist_entry in "${data_blacklist[@]}"; do
    if [ -n "${data_blacklist_entry}" ]; then
      echo "0.0.0.0 ${data_blacklist_entry}" >>"${FILE_TEMP}"
    fi
  done

  # sort file entries and remove multiple occuring entries
  log "sort file entries and remove multiple occuring entries"
  sort -u -o "${FILE_TEMP}" "${FILE_TEMP}"

  # duplicate data for IPv6 (e.g. dnsmasq needs such entries to block IPv6 hosts)
  if [ "${ipv6dup}" -eq 1 ]; then
    log "duplicate data for IPv6 in temp file '${FILE_TEMP_IPV6}'"
    cp "${FILE_TEMP}" "${FILE_TEMP_IPV6}"
    "${SED_COMMAND}" -i -e 's/0.0.0.0/::0/g' "${FILE_TEMP_IPV6}"
    cat "${FILE_TEMP_IPV6}" >>"${FILE_TEMP}"
    rm -f "${FILE_TEMP_IPV6}"
  fi

  # generate and write file header
  log "generating and writing file header"
  local -r data_header="# clean merged adblocking-hosts file\n\
# more infos: https://github.com/monojp/hosts_merge\n\
\n\
127.0.0.1 localhost\n\
::1 localhost\n"
  "${SED_COMMAND}" -i "1i${data_header}" "${FILE_TEMP}"

  local -r domain_count=$(grep -c '^0.0.0.0 ' "${FILE_TEMP}")
  log "domains on block list: ${domain_count}"

  # rotate in place
  log "move temp file '$FILE_TEMP' to '$FILE_RESULT'"
  mv -f "${FILE_TEMP}" "${FILE_RESULT}"

  # fixup permissions (we don't want that limited temp perms)
  log "chmod '${FILE_RESULT}' to '${PERMISSIONS_RESULT}'"
  chmod ${PERMISSIONS_RESULT} "${FILE_RESULT}"

  cleanup
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
    FILE_RESULT=${var/output=/}
  elif [[ "${var}" == "ipv6dup" ]]; then
    ipv6dup=1
  # unknown or wrong command, print usage
  else
    print_usage
    exit
  fi
done
readonly mode_verbose
readonly mode_check
readonly mode_clean
readonly ipv6dup

main "$@"
