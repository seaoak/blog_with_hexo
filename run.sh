#!/bin/sh

set -e

#cat <<END |
#hexo							../../hexo
#hexo-filter-date-from-git		../../hexo-filter-date-from-git
#hexo-server						../../hexo-server
#hexo-util						../../hexo-util
#END
#
#grep -E '^[a-z]' |
#(
#	set -e
#	set -x
#
#	cd node_modules
#	while read NAME DIR; do
#		test -d $DIR
#		if [ -d $DIR/node_modules -a ! -h $DIR/node_modules ]; then
#			test ! -d $DIR/node_modules.bak
#			(cd $DIR; mv node_modules node_modules.bak)
#		fi
#
#		test -d $NAME
#		if [ ! -h $NAME ]; then
#			rm -r $NAME
#			ln -s $DIR $NAME
#		fi
#	done
#)

PREFIX='/usr/bin/nice -n -19 '

set -x

$PREFIX which node
$PREFIX node --version
$PREFIX npm --version
$PREFIX hexo -V
$PREFIX hexo clean --debug
if [ "X$1" = 'Xgenerate' ]; then
    $PREFIX hexo generate --debug
    exit $?
fi
$PREFIX hexo server -i 127.0.0.1 -p 5958 --debug
