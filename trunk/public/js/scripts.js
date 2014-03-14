function url_clean(url) {
	if (url.indexOf('?') != -1)
		url = url.substr(0, url.indexOf('?'));
	return url;
}
function build_url() {
	var checked = $('[name="check_src"]:checked');
	var blacklist_checked = $('#check_blacklist').is(':checked');
	var whitelist_checked = $('#check_whitelist').is(':checked');

	// all checked
	if (
		checked.length == $('[name="check_src"]').length &&
		blacklist_checked && whitelist_checked
	)
		var url = url_clean(document.location.href) + '?src=all';
	// build url out of src parts
	else {
		var url = url_clean(document.location.href) + '?src=';
		checked.each(function() {
			url += $(this).val() + ',';
		});
		url = url.substring(0, url.length - 1);
		if (blacklist_checked)
			url += '&black';
		if (whitelist_checked)
			url += '&white';
	}
	// nothing checked
	if (
		checked.length == 0 &&
		!blacklist_checked && !whitelist_checked
	) {
		$('#url').html('-');
		$('#url').attr('href', 'javascript:void(0)');
	}
	else {
		$('#url').html(url);
		$('#url').attr('href', url);
	}
}

// init
$(document).ready(function() {
	// build url on change
	$('input[type="checkbox"]').change(function() {
		build_url();
	});
	// change language handler
	$('#lang').change(function() {
		document.location.href = url_clean(document.location.href) + '?lang=' + $('#lang').val();
	});
});
