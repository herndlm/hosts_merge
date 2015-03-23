<?php

require_once __DIR__ . '/../includes/includes.php';

// get local blacklist and whitelist entries
$blacklist_data = trim(file_get_contents(BLACKLIST));
$whitelist_data = trim(file_get_contents(WHITELIST));

// download hosts file
if (isset($_GET['src'])) {
	$hosts_data = array();

	// add all sources selected
	foreach ($sources as $source_url) {
		// use local source cache
		$hosts_data[] = file_get_contents_cache($source_url);
	}

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
$titlebar_right_form_data = html_tag('label', $tr->__('Language:'), array('for' => 'lang'));
$lang_select_data = '';
foreach ($languages as $key => $language) {
	if ($key == $lang)
			$lang_select_data .= html_tag('option', $language, array('value' => $key, 'selected' => 'selected'));
	else
		$lang_select_data .= html_tag('option', $language, array('value' => $key));
}
$titlebar_right_form_data .= html_tag('select', $lang_select_data, array('name'  => 'lang', 'id' => 'lang', 'onchange' => 'document.getElementById("lang_form").submit()'));
$titlebar_right = html_tag('form', $titlebar_right_form_data, array('action' => 'index.php', 'method' => 'GET', 'id' => 'lang_form'));
$titlebar = html_tag('div', $titlebar_left, array('class' => 'titlebar_inner float_left'));
$titlebar .= html_tag('div', $titlebar_right, array('class' => 'titlebar_inner float_right'));
echo html_tag('div', $titlebar, array('id' => 'titlebar'));

// description
$content = html_tag('h2', $tr->__('Level up your browsing experience'));
$content .= html_tag('p',
	$tr->__('You can combine hosts files for adblocking or tracking/privacy reasons here.') . ' ' .
	$tr->__("By using such an hosts file your computer can't make a connection to any of the domains listed in it any more.") . ' ' .
	$tr->__('This is the fastest and most secure way of blocking unwanted ads and shady sites.') . ' ' .
	$tr->__('Additionaly it should also speed up your surfing experience :)'),
array('style' => 'max-width: 40em'));
$content .= html_tag('p',
	$tr->__('Duplicates and non existing domains are removed to keep the file clean!')
);
//$content .= html_tag('a', $tr->

// step 1, show sources
$step_data = html_tag('span', $tr->__('Sources'), array('class' => 'bold'));
$sources_input = '';
$sources_show = array_merge($sources, $sources_show_only);
foreach ($sources_show as $source) {
	$sources_input .= html_tag('li', html_tag('a', htmlspecialchars($source), array('href' => htmlspecialchars($source), 'target' => '_blank')), array(
		'class' => 'middle',
		'style' => 'margin-left: .2em'
	));
}
$step_data .= html_tag('ul', $sources_input);
$content .= html_tag('div', $step_data, array('class' => 'dynamic_block'));

// step 2, check blacklist
/*$step_data = html_tag('p',
	html_tag('label', $tr->__('Blacklist'), array('for' => 'text_blacklist')),
	array('class' => 'bold')
);
$step_data .= html_tag('textarea', $blacklist_data, array(
	'id'       => 'text_blacklist',
	'name'     => 'text_blacklist',
	'rows'     => '5',
	'cols'     => '29',
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
$content .= html_tag('div', $step_data, array('class' => 'dynamic_block'));

// step 3, check whitelist
$step_data = html_tag('p',
	html_tag('label', $tr->__('Whitelist'), array('for' => 'text_whitelist')),
	array('class' => 'bold')
);
$step_data .= html_tag('textarea', $whitelist_data, array(
	'id'       => 'text_whitelist',
	'name'     => 'text_whitelist',
	'rows'     => '5',
	'cols'     => '29',
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
$content .= html_tag('div', $step_data, array('class' => 'dynamic_block'));*/

// end float
$content .= html_tag('div', null, array('class' => 'float_clear'));

// step 4, download hosts file
$hosts_url = current_url() . '?src=all';
$step_data = html_tag('p', $tr->__('Download hosts file'), array('class' => 'bold'));
$step_data .= html_tag('a', $hosts_url , array(
	'id'       => 'url',
	'href'     => $hosts_url,
));
$content .= html_tag('div', $step_data, array('style' => 'margin: .5em'));

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
		'title'    => $tr->__('Needs a rooted device and BusyBox'),
	))
;
$content .= html_tag('div', $step_data, array('style' => 'margin: .5em'));

// contact / legal info
$outputs = array();
if (CONTACT_HREF)
	$outputs[] = html_tag('a', $tr->__('Contact'), array('href' => htmlspecialchars(CONTACT_HREF), 'target' => '_blank'));
if (IMPRESSUM_HREF)
	$outputs[] = html_tag('a', $tr->__('Legal notice'), array('href' => htmlspecialchars(IMPRESSUM_HREF), 'target' => '_blank'));
if (PRIVACY_INFO)
	$outputs[] = html_tag('a', $tr->__('Privacy notice'), array('href' => 'javascript:void(0)', 'title' => htmlspecialchars(PRIVACY_INFO), 'target' => '_blank'));
$outputs[] = html_tag('a', $tr->__('Open Source'), array(
	'href'   => 'https://github.com/monojp/blockemhosts/',
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
