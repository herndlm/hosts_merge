<?php

define('TITLE', 'BlockEmHosts.org');
define('META_KEYWORDS', 'blockemout hosts files adblock privacy tracking');
define('META_DESCRIPTION', 'combine hosts files for adblocking / privacy reasons');
define('CONTACT_HREF', '<contact site>');
define('IMPRESSUM_HREF', '<impressum site>');
define('PRIVACY_INFO', '<privacy info>');

define('USE_MINIMZED_JS_CSS_HTML', false);

define('LANG_DIR', __DIR__ . '/../includes/lang');
define('CACHE', __DIR__ . '/../cache');
define('WHITELIST', __DIR__ . '/../includes/whitelist');
define('BLACKLIST', __DIR__ . '/../includes/blacklist');
define('CACHE_SECONDS', 60*60*60*24);

date_default_timezone_set('Europe/Vienna');

/*
 * a file with the translations has
 * to exist in includes/lang/<id.txt>
 */
$languages = array(
	'en' => 'English',
);
/*
 * sources which are shown in GUI (only hostname)
 * the left number is used as ID for the sources
 * and therefore should never be changed
 * to avoid issues with bookmarked urls
 */
$sources = array(
	'1' => '<href',
);

$local_ips = array(
	'127.0.0.1',
	'0.0.0.0',
);
$local_hosts = array(
	'localhost',
	'localhost.localdomain',
	'broadcasthost',
	'local',
);

$tracking_code = '';

?>
