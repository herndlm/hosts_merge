<?php

require_once('config.php');
require_once('Translator.php');

header("Vary: Accept-Encoding");
header("Content-Type: application/xhtml+xml; charset=UTF-8");

// cache 1 week
$seconds_to_cache = 604800;
$ts = gmdate("D, d M Y H:i:s", time() + $seconds_to_cache) . " GMT";
header("Expires: $ts");
header("Pragma: cache");
header("Cache-Control: private, post-check=900, pre-check=$seconds_to_cache, max-age=$seconds_to_cache");

$lang = getDefaultLanguage();
if (isset($_GET['lang']))
	$lang = $_GET['lang'];
$tr = new Translator($lang);

// get default language key (2 chars) for user
function getDefaultLanguage() {
	if (isset($_SERVER['HTTP_ACCEPT_LANGUAGE']))
		return substr(parseDefaultLanguage($_SERVER['HTTP_ACCEPT_LANGUAGE']), 0, 2);
	else
		return substr(parseDefaultLanguage(null), 0, 2);
}
// parse default language of HTTP_ACCEPT_LANGUAGE header
function parseDefaultLanguage($http_accept, $deflang = 'en') {
	if (isset($http_accept) && strlen($http_accept) > 1)  {
		// Split possible languages into array
		$x = explode(',' ,$http_accept);
		foreach ($x as $val) {
			// check for q-value and create associative array. No q-value means 1 by rule
			if (preg_match("/(.*);q=([0-1]{0,1}\.\d{0,4})/i", $val, $matches))
				$lang[$matches[1]] = (float)$matches[2];
			else
				$lang[$val] = 1.0;
		}

		// return default language (highest q-value)
		$qval = 0.0;
		foreach ($lang as $key => $value) {
			if ($value > $qval) {
				$qval = (float)$value;
				$deflang = $key;
			}
		}
	}
	return strtolower($deflang);
}
// get current access url without query
function current_url() {
	$url = (isset($_SERVER['HTTP_HOST']) && isset($_SERVER['REQUEST_URI'])) ? "http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]" : null;
	if (strpos($url, '?') !== false)
		$url = substr($url, 0, strpos($url, '?'));
	return $url;
}
// get the host out of an url
function host_from_url($url) {
	$data = parse_url($url);
	return isset($data['host']) ? $data['host'] : null;
}
// adds a last modification timestamp to an url to avoid caching errors
function cacheSafeUrl($file) {
	return $file . "?" . filemtime($file);
}
// removes unecessary data (newlines, ..) from html
function html_compress($html) {
	// no minimized html, return
	if (!USE_MINIMZED_JS_CSS_HTML)
		return $html;
	// remove javascript comments
	$response = preg_replace('%/\*(.|[\r\n])*?\*/%', '', $html);
	// convert multiple spaces into one
	$response = preg_replace('/\s{2,}/', ' ', $response);
	// tabs and carriage return
	$response = str_replace(array("\t", "\r"), '', $response);
	// cleanup spaces inside tags
	$response = str_replace(' />', '/>', $response);

	return $response;
}
// wrapper for creating html tags
function html_tag($name, $content = null, $attributes = null) {
	if (is_array($attributes)) {
		foreach ($attributes as $attr => $value) {
			$attributes_clean[] = "$attr='$value'";
		}
		$attributes = implode(' ', $attributes_clean);
	}

	$valid_self_closing_tags = array('img', 'input', 'br');

	if ($attributes && $content)
		return "<$name $attributes>$content</$name>";
	else if ($attributes && !$content && in_array($name, $valid_self_closing_tags))
		return "<$name $attributes/>";
	else if ($attributes && !$content && !in_array($name, $valid_self_closing_tags))
		return "<$name $attributes></$name>";
	else if (!$attributes && $content)
		return "<$name>$content</$name>";
	else if (!in_array($name, $valid_self_closing_tags))
		return "<$name></$name>";
	else
		return "<$name/>";
}
// file getter via local cache
// downloads a file once and serves it from cache
// until the downloaded copy is older than $max_cache_seconds seconds
function file_get_contents_cache($url, $max_cache_seconds = CACHE_SECONDS) {
	$timestamp = time();
	$filename = basename($url);
	$prefix = host_from_url($url);
	$prefix = preg_replace('/[^0-9a-zA-Z]/', '', $prefix);
	$cache_path = CACHE . '/' . $prefix . md5($filename);

	// local file exists
	if (file_exists($cache_path)) {
		$data = file_get_contents($cache_path);
		// data ok and not too old
		if (
			!empty($data) &&
			abs($timestamp - filemtime($cache_path)) < $max_cache_seconds
		)
			return $data;
	}

	// still here? download file to local cache and return
	$data = file_get_contents($url);
	file_put_contents($cache_path, $data);
	return $data;
}
// writes the propriate data of the url to the cache manually
function file_put_contents_cache($url, $data) {
	$filename = basename($url);
	$prefix = host_from_url($url);
	$prefix = preg_replace('/[^0-9a-zA-Z]/', '', $prefix);
	$cache_path = CACHE . '/' . $prefix . md5($filename);
	file_put_contents($cache_path, $data);
}
// gets the clean domain name of an hosts line
// strips and ignores comments or localhost definitions
function hosts_line_get_domain($line) {
	global $local_hosts, $strings_start_strip, $strings_to_strip;

	// strip local ip part from start
	// ignore line if nothing removed
	$string_stripped = false;
	foreach ($strings_start_strip as $string) {
		$pos = strpos($line, $string);
		if ($pos === 0) {
			$line = str_replace($string, '', $line);
			$string_stripped = true;
			break;
		}
	}
	if (!$string_stripped)
		return null;
	// remove ending comment
	$start_comment = strpos($line, '#');
	if ($start_comment !== false)
		$line = substr($line, 0, $start_comment);
	// strip strings
	foreach ($strings_to_strip as $string)
		$line = str_replace($string, '', $line);
	// cleanup line
	$line = trim($line);
	// ignore localhost definitions or empty entries
	if (in_array($line, $local_hosts) || empty($line))
		return null;

	return $line;
}
// merges two or more hosts files together
// TODO make this more memory friendly (e.g. line per line)
function hosts_merge($hosts_data, $blacklist_data=null, $whitelist_data=null, $redirect_to='0.0.0.0') {
	$entries = array();

	foreach ($hosts_data as $data) {
		foreach((array)explode(PHP_EOL, $data) as $line) {
			$domain = hosts_line_get_domain($line);
			// add to array as unique key
			if ($domain)
				$entries[$domain] = null;
		}
	}

	// add malwarepatrol domain list
	$malwarepatrol_contents = file_get_contents_cache('https://www.malwarepatrol.net/cgi/submit?action=stats&s=domains#domains');
	if ($malwarepatrol_contents) {
		$doc = new DOMDocument();
		if ($doc->loadHTML($malwarepatrol_contents)) {
			$domains = $doc->getElementsByTagName('font');
			foreach ($domains as $domain) {
				$domain_entry = trim($domain->nodeValue);
				if (!empty($domain_entry))
					$entries[$domain_entry] = null;
			}
		}
	}

	// add koffix domain list
	$koffix_contents = file_get_contents_cache('http://koffix.com/research/sites/');
	if ($koffix_contents) {
		$doc = new DOMDocument();
		if ($doc->loadHTML($koffix_contents)) {
			$content = $doc->getElementById('brickup-document');
			$hrefs = $content->getElementsByTagName('a');
			foreach ($hrefs as $href) {
				$domain_entry = trim($href->nodeValue);
				if (!empty($domain_entry))
					$entries[$domain_entry] = null;
			}
		}
	}

	// add hosts from blacklist
	if (!empty($blacklist_data)) {
		$blacklist_data = explode(PHP_EOL, $blacklist_data);
		$blacklist_data = array_unique($blacklist_data);
		foreach ((array)$blacklist_data as $host)
			$entries[$host] = null;
	}

	// remove hosts from whitelist
	if (!empty($whitelist_data)) {
		$whitelist_data = explode(PHP_EOL, $whitelist_data);
		$whitelist_data = array_unique($whitelist_data);
		foreach ($whitelist_data as $host)
			unset($entries[$host]);
	}

	// sort entries, implode in
	// hosts file syntax and return
	ksort($entries);
	$entries = array_keys($entries);
	if (!empty($entries))
		return $redirect_to . ' ' . implode("\n$redirect_to ", $entries) . "\n";
	return null;
}
// create the header for the hosts file
function hosts_header() {
	return
		"# clean merged adblocking-hosts file\n" .
		"# source: $_SERVER[HTTP_HOST]\n" .
		"# build date: " . date(DATE_ATOM) . "\n\n" .

		"127.0.0.1 localhost.localdomain localhost\n" .
		"::1 localhost.localdomain localhost\n\n"
	;
}

?>