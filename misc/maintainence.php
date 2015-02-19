<?php

require_once __DIR__ . '/../includes/includes.php';

$command = isset($argv[1]) ? $argv[1] : null;

// lookup cache because it's easily possible that
// same hosts are in multiple source files
$domains_lookup_cache = array();
function query_domain_lookup_cache($domain) {
	global $domains_lookup_cache;
	if (!isset($domains_lookup_cache[$domain]))
		$domains_lookup_cache[$domain] = gethostbyname($domain);
	return $domains_lookup_cache[$domain];
}

// pre-cache
if ($command == 'cache') {
	// query all sources
	foreach ($sources as $source_id => $source_url) {
		file_get_contents_cache($source_url, CACHE_SECONDS);
	}
}
// pre-cache and remove non existing host entries
else if ($command == 'cache_lookup') {
	// check sources
	foreach ($sources as $sources_id => $source_url) {
		// force get and pre-cache data
		$data = file_get_contents_cache($source_url, 0);

		// remove non existing entries
		$data = explode(PHP_EOL, $data);
		foreach((array)$data as $index => $line) {
			$domain = hosts_line_get_domain($line);
			if ($domain) {
				if ($domain == query_domain_lookup_cache($domain)) {
					unset($data[$index]);
				}
			}
		}
		$data = implode("\n", $data);

		// write data to cache again
		file_put_contents_cache($source_url, $data);
	}

	// check blacklist
	$blacklist_data = trim(file_get_contents(BLACKLIST));
	$blacklist_data = explode(PHP_EOL, $blacklist_data);
	foreach ($blacklist_data as $index => $domain) {
		$domain = strip_bash_comments($domain);
		if (!empty($domain) && $domain == query_domain_lookup_cache($domain)) {
			error_log("$index: $domain not existing");
			unset($blacklist_data[$index]);
		}
	}
	$blacklist_data = array_unique($blacklist_data);
	sort($blacklist_data);
	$blacklist_data = implode("\n", $blacklist_data);
	file_put_contents(BLACKLIST, $blacklist_data);

	// check whitelist
	$whitelist_data = trim(file_get_contents(WHITELIST));
	$whitelist_data = explode(PHP_EOL, $whitelist_data);
	foreach ($whitelist_data as $index => $domain) {
		$domain = strip_bash_comments($domain);
		if (!empty($domain) && $domain == query_domain_lookup_cache($domain)) {
			error_log("$index: $domain not existing");
			unset($whitelist_data[$index]);
		}
	}
	$whitelist_data = array_unique($whitelist_data);
	sort($whitelist_data);
	$whitelist_data = implode("\n", $whitelist_data);
	file_put_contents(WHITELIST, $whitelist_data);
}
else
	exit("error, parameter action [cache|cache_lookup] invalid!\n");

?>