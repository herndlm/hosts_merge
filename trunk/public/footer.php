<?php

require_once __DIR__ . '/../includes/includes.php';

if (!empty($tracking_code))
	echo $tracking_code;

echo '</body></html>';

// write custom compressed output buffer
ob_end_flush();

?>
