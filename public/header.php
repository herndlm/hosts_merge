<?php

require_once __DIR__ . '/../includes/includes.php';

header("Vary: Accept-Encoding");
header("Content-Type: text/html; charset=UTF-8");

// cache 1 hour
$seconds_to_cache = 3600;
$ts = gmdate("D, d M Y H:i:s", time() + $seconds_to_cache) . " GMT";
header("Expires: $ts");
header("Pragma: cache");
header("Cache-Control: private, post-check=900, pre-check=$seconds_to_cache, max-age=$seconds_to_cache");

// start output buffering with custom html compress handler
ob_start('html_compress');

echo '<!DOCTYPE html>';
echo '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="' . $lang . '" lang="' . $lang . '">';
echo '<head>';
echo '<title>' . TITLE . '</title>';
echo '<meta charset="UTF-8" />';
echo '<meta name="robots" content="INDEX,FOLLOW" />';
echo '<meta name="keywords" content="' . META_KEYWORDS . '" />';
echo '<meta name="description" content="' .  META_DESCRIPTION . '" />';
echo '<meta name="viewport" content="width=device-width" />';

// css and javascript
$headLoadJS = 'js/head.load.min.js';
$jqueryJS = 'js/jquery-1.11.0.min.js';
$jqueryUiJS = 'js/jquery-ui-1.10.4.custom.min.js';
if (USE_MINIMZED_JS_CSS_HTML) {
	$stylesCSS = 'css/styles-min.css';
	$jqeryuiCSS = 'css/black-tie/jquery-ui-1.10.4.custom.min.css';
	$scriptsJS = 'js/scripts-min.js';
}
else {
	$stylesCSS = 'css/styles.css';
	$jqeryuiCSS = 'css/black-tie/jquery-ui-1.10.4.custom.css';
	$scriptsJS = 'js/scripts.js';
}
// basic css
echo '
	<link rel="stylesheet" type="text/css" href="' . cacheSafeUrl($stylesCSS) . '" />
	<link rel="stylesheet" type="text/css" href="' . cacheSafeUrl($jqeryuiCSS) . '" />
';
// javascript
echo '
	<script src="' . cacheSafeUrl($headLoadJS) . '" type="text/javascript"></script>
	<script type="text/javascript">
		head.js("' . cacheSafeUrl($jqueryJS) . '", function() {
			head.js(
				{scripts: "' . cacheSafeUrl($scriptsJS) . '"}
			);
		});
		head.js("' . cacheSafeUrl($jqueryUiJS) . '", function() {
			/* add jqeryui dependencies here */
		});
	</script>
';

?>
