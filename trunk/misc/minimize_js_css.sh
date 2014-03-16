#!/bin/sh

BASEDIR=$(dirname $0)

java -jar $BASEDIR/yuicompressor-2.4.8.jar --type css $BASEDIR/../public/css/styles.css -o $BASEDIR/../public/css/styles-min.css
java -jar $BASEDIR/yuicompressor-2.4.8.jar --type css $BASEDIR/../public/css/black-tie/jquery-ui-1.10.4.custom.css -o $BASEDIR/../public/css/black-tie/jquery-ui-1.10.4.custom.min.css

java -jar $BASEDIR/yuicompressor-2.4.8.jar --type js $BASEDIR/../public/js/scripts.js -o $BASEDIR/../public/js/scripts-min.js