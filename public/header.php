<?php

require_once __DIR__ . '/../includes/includes.php';

// start output buffering with custom html compress handler
ob_start('html_compress');

echo '<!DOCTYPE html>';
echo "<html lang='${lang}'>";
echo '<head>';
echo '<title>' . TITLE . '</title>';
echo '<meta charset="UTF-8" />';
echo '<meta name="robots" content="INDEX,FOLLOW" />';
echo '<meta name="keywords" content="' . META_KEYWORDS . '" />';
echo '<meta name="description" content="' .  META_DESCRIPTION . '" />';
echo '<meta name="viewport" content="width=device-width" />';

// css and javascript
if (USE_MINIMZED_JS_CSS_HTML)
	$stylesCSS = 'css/styles-min.css';
else
	$stylesCSS = 'css/styles.css';
// basic css
echo '
	<link rel="stylesheet" type="text/css" href="' . cacheSafeUrl($stylesCSS) . '" />
';

?>
