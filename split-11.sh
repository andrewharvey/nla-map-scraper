#!/bin/sh

# This file was originally authored by Andrew Harvey <andrew.harvey4@gmail.com>

# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/


	while read line
	do
		a="11-map-landing/index.html?pi=$line"
		b="14-map-landing-single/$line"
		#mv "$a" "$b"
		ln -s -T "../$a" "$b"
	done <12-landing-pages-one-part.txt
	
	while read line
	do
		a="11-map-landing/index.html?pi=$line"
		b="15-map-landing-many/$line"
		#mv "$a" "$b"
		ln -s -T "../$a" "$b"
	done <13-landing-pages-many-parts.txt
