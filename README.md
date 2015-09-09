# hosts_merge
merge hostfiles for adblocking / privacy reasons

Bash script which merges domain data from different sources together to one hosts file for blocking.

```
USAGE: <script> [verbose] [check] [clean] [output=<filename>]

verbose: print more info about what is going on
check: checks the whitelist and blacklist (whitelisted entries should exist and blacklisted entries should not exist in the uncleaned hosts data)
clean: cleanup whitelist and blacklist files ('check' should be run first)
ipv6dup: duplicate all the domains with '::0' as prefix instead of '0.0.0.0'
```

If you're just looking for an up-to-date hosts file, you should probably check http://hosts.herndl.org/hosts.txt
