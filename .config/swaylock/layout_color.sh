#!/usr/bin/bash
grayscale=$(/usr/bin/grim -g "445,590 395x80" - | /usr/bin/convert - -resize 1x1\! -colorspace Gray -format "%[fx:int(255*c)]" info:-)
if (( "$grayscale" > 127 ))
then
	echo 1d2021
	exit
fi

echo ebdbb2
