<?php

require_once __DIR__ . '/../includes/includes.php';

// get local blacklist and whitelist entries
$blacklist_data = trim(file_get_contents(BLACKLIST));
$whitelist_data = trim(file_get_contents(WHITELIST));

// download hosts file
if (isset($_GET['src'])) {
	$hosts_data = array();
	$all = (strpos($_GET['src'], 'all') !== false);
	$sources_ids = explode(',', $_GET['src']);

	// add all sources selected
	foreach ($sources as $source_id => $source_url) {
		if (!$all && !in_array($source_id, $sources_ids))
			continue;
		// use 1 week local source cache
		$hosts_data[] = file_get_contents_cache($source_url, 60*60*60*24*7);
	}

	// no blacklist / whitelist needed
	if (!$all && !isset($_GET['black']))
		$blacklist_data = null;
	if (!$all && !isset($_GET['white']))
		$whitelist_data = null;

	$data = hosts_header();
	$data .= hosts_merge($hosts_data, $blacklist_data, $whitelist_data);
	header('Content-Description: File Transfer');
	header('Content-Type: application/octet-stream');
	header('Content-Disposition: attachment; filename=hosts.txt');
	header('Content-Transfer-Encoding: binary');
	header('Expires: 0');
	header('Cache-Control: must-revalidate');
	header('Pragma: public');
	header('Content-Length: ' . strlen($data));
	echo $data;
	exit;
}

// header
require_once('header.php');
echo '</head><body>';

// titlebar
$titlebar_left = html_tag('h1', TITLE);
$titlebar_right = html_tag('label', $tr->__('Language:'), array('for' => 'lang'));
$lang_select_data = '';
foreach ($languages as $key => $language) {
	if ($key == $lang)
		$lang_select_data .= html_tag('option', $language, array('value' => $key, 'selected' => 'selected'));
	else
		$lang_select_data .= html_tag('option', $language, array('value' => $key));
}
$titlebar_right .= html_tag('select', $lang_select_data, array('name'  => 'lang', 'id' => 'lang'));
$titlebar = html_tag('div', $titlebar_left, array('class' => 'titlebar_inner float_left'));
$titlebar .= html_tag('div', $titlebar_right, array('class' => 'titlebar_inner float_right'));
echo html_tag('div', $titlebar, array('id' => 'titlebar'));

// stop image floated right
$content = html_tag('div',
	html_tag('img', null, array(
		'src'    => cacheSafeUrl('images/stop.png'),
		'alt'    => 'stop shield',
		'width'  => '200',
		'height' => '224',
	)
), array('class'  => 'float_right'));
$content .= html_tag('h2', $tr->__('Level up your browsing experience'));
$content .= html_tag('p',
	$tr->__('You can combine hosts files for adblocking or tracking/privacy reasons here.') . ' ' .
	$tr->__("By using such an hosts file your computer can't make a connection to any of the domains listed in it any more.") . ' ' .
	$tr->__('This is the fastest and most secure way of blocking unwanted ads and shady sites.') . ' ' .
	$tr->__('Additionaly it should also speed up your surfing experience :)')
);
//$content .= html_tag('a', $tr->

// step 1, select sources
$step_data = html_tag('p', $tr->__('Choose sources'), array('class' => 'bold'));
$sources_input = array();
foreach ($sources as $id => $source) {
	$sources_input[] =
		html_tag('input', null, array(
			'type'    => 'checkbox',
			'id'      => $id,
			'name'    => 'check_src',
			'value'   => $id,
			'checked' => 'checked',
			'class'   => 'middle',
		)) .
		html_tag('label', host_from_url($source), array(
			'for'   => $id,
			'title' => htmlspecialchars($source),
			'class' => 'middle',
			'style' => 'margin-left: 5px'
		));
}
$step_data .= implode('<br/>', $sources_input);
$content .= html_tag('div', $step_data, array('class' => 'float_left', 'style' => 'margin: 10px'));

// step 2, check blacklist
$step_data = html_tag('p',
	html_tag('label', $tr->__('Blacklist'), array('for' => 'text_blacklist')),
	array('class' => 'bold')
);
$step_data .= html_tag('textarea', $blacklist_data, array(
	'id'       => 'text_blacklist',
	'name'     => 'text_blacklist',
	'rows'     => '5',
	'cols'     => '26',
	'disabled' => 'disabled',
	'style'    => 'background-color: #FFDDDD',
));
$step_data .= html_tag('br');
$step_data .= html_tag('input', null, array(
	'type'    => 'checkbox',
	'id'      => 'check_blacklist',
	'name'    => 'check_blacklist',
	'checked' => 'checked',
	'class'   => 'middle',
));
$step_data .= html_tag('label', $tr->__('Include Blacklist'), array('for' => 'check_blacklist', 'class' => 'middle'));
$content .= html_tag('div', $step_data, array('class' => 'float_left', 'style' => 'margin: 10px'));

// step 3, check whitelist
$step_data = html_tag('p',
	html_tag('label', $tr->__('Whitelist'), array('for' => 'text_whitelist')),
	array('class' => 'bold')
);
$step_data .= html_tag('textarea', $whitelist_data, array(
	'id'       => 'text_whitelist',
	'name'     => 'text_whitelist',
	'rows'     => '5',
	'cols'     => '26',
	'disabled' => 'disabled',
	'style'    => 'background-color: #DDFFDD'
));
$step_data .= html_tag('br');
$step_data .= html_tag('input', null, array(
	'type'    => 'checkbox',
	'id'      => 'check_whitelist',
	'name'    => 'check_whitelist',
	'checked' => 'checked',
	'class'   => 'middle',
));
$step_data .= html_tag('label', $tr->__('Include Whitelist'), array('for' => 'check_whitelist', 'class' => 'middle'));
$content .= html_tag('div', $step_data, array('class' => 'float_left', 'style' => 'margin: 10px'));

// end float
$content .= html_tag('div', null, array('class' => 'float_clear'));

// step 4, download hosts file
//$hosts_url = current_url() . '?src=' . implode(',', array_keys($sources));
$hosts_url = current_url() . '?src=all';
$step_data = html_tag('p', $tr->__('Download hosts file'), array('class' => 'bold'));
$step_data .= html_tag('a', $hosts_url , array(
	'id'       => 'url',
	'href'     => $hosts_url,
	'download' => 'download',
));
$content .= html_tag('div', $step_data, array('style' => 'margin: 10px'));

// step 5, download install scripts
$step_data = html_tag('p', $tr->__('Download install script'), array('class' => 'bold'));
$step_data .= 
	html_tag('a', $tr->__('Windows Installer'), array(
		'href'     => 'hosts_windows.bat',
		'download' => 'hosts_windows.bat',
		'title'    => $tr->__('Has to be run as administrator (right click - run as administrator)'),
	)) .
	html_tag('br') . 
	html_tag('a', $tr->__('Linux Installer'), array(
		'href'     => 'hosts_linux.sh',
		'download' => 'hosts_linux.sh',
		'title'    => $tr->__('Has to be run as root'),
	)) .
	html_tag('br') . 
	html_tag('a', $tr->__('Android Installer'), array(
		'href'     => 'hosts_android.sh',
		'download' => 'hosts_android.sh',
		'title'    => $tr->__('Needs a rooted device and an app which can run shell scripts or has to be run via adb'),
	))
;
$content .= html_tag('div', $step_data, array('style' => 'margin: 10px'));

// contact / legal info
$outputs = array();
if (CONTACT_HREF)
	$outputs[] = html_tag('a', $tr->__('Contact'), array('href' => htmlspecialchars(CONTACT_HREF), 'target' => '_blank'));
if (IMPRESSUM_HREF)
	$outputs[] = html_tag('a', $tr->__('Legal notice'), array('href' => htmlspecialchars(IMPRESSUM_HREF), 'target' => '_blank'));
if (PRIVACY_INFO)
	$outputs[] = html_tag('a', $tr->__('Privacy notice'), array('href' => 'javascript:void(0)', 'title' => htmlspecialchars(PRIVACY_INFO), 'target' => '_blank'));
$outputs[] = html_tag('a', $tr->__('Open Source'), array(
	'href'   => 'https://code.google.com/p/blockemhosts/',
	'target' => '_blank',
	'title'  => $tr->__('BlockEmHosts.org is Open Source. Go check it out by clicking here.')
));
$content .= html_tag('div', implode(' | ', $outputs), array('class' => 'float_right'));

// end float
$content .= html_tag('div', null, array('class' => 'float_clear'));

echo html_tag('div', $content, array('id' => 'content'));

// footer
require_once('footer.php');

?>
