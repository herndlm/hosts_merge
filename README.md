# hosts_merge
merge hostfiles for adblocking / privacy reasons

Bash script which merges domain data from different sources together to one hosts file for blocking.

```
USAGE: <script> [verbose] [check] [clean] [ipv6dup] [output=<filename>]

verbose: print more info about what is going on
check: check: checks the whitelist and blacklist (whitelisted entries should exist and blacklisted entries should not exist in the uncleaned hosts data), furthermore non-resolving domains from the blacklist are reported
clean: clean: cleanup whitelist and blacklist files (fixes the issues reported by check)
ipv6dup: duplicate all the domains with '::0' as prefix instead of '0.0.0.0'
```

I also collect a blocklist with common ad and tracking domains at https://raw.githubusercontent.com/monojp/hosts_merge/master/hosts_blacklist.txt
