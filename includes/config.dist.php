<?php

define('TITLE', 'BlockEmHosts.org');
define('META_KEYWORDS', 'blockemout hosts files adblock privacy tracking');
define('META_DESCRIPTION', 'combine hosts files for adblocking / privacy reasons');
define('CONTACT_HREF', '<contact site>');
define('IMPRESSUM_HREF', '<impressum site>');
define('PRIVACY_INFO', '<privacy info>');

define('USE_MINIMZED_JS_CSS_HTML', false);

define('CACHE', '../cache');
define('WHITELIST', '../includes/whitelist');
define('BLACKLIST', '../includes/blacklist');

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

?>
