<?php

// improvised version of http://tympanus.net/codrops/2009/12/30/easy-php-site-translation/

class Translator {
	private $lang         = 'en';
	private $translations = array();

	public function __construct($lang){
		$this->lang = $lang;

		if (file_exists('./' . LANG_DIR . "/$lang.txt")) {
			$strings = array_map(array($this, 'splitStrings'), file('./' . LANG_DIR . "/$lang.txt"));
			foreach ($strings as $k => $v) {
				if (isset($v[1]) && !empty($v[1]))
					$this->translations[$lang][$v[0]] = $v[1];
			}
		}
	}

	private function splitStrings($str) {
		return explode('=',trim($str));
	}

	public function __($str) {
		if (isset($this->translations[$this->lang][$str]))
			return $this->translations[$this->lang][$str];
		return $str;
	}
}

?>
