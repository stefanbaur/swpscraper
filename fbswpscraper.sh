#!/bin/bash

# source config
. ./fbswpscraper.config

# Path and file name for sqlite database
[ -z "$DBFILE" ] && DBFILE="/run/FBSWPDB"

# Path, file name, and parameters for command line Twitter client
[ -z "$TWITTER" ] && TWITTER="../oysttyer/oysttyer.pl -script"

if [ -z "$ALTERNATETWITTERCREDENTIALSFILE" ] ; then
	ALTERNATETWITTERCREDENTIALSFILE=""
else
	[ -n "$ALTERNATETWITTERCOMMAND=" ] && ALTERNATETWITTERCOMMAND="$TWITTER -keyf=$ALTERNATETWITTERCREDENTIALSFILE "
fi

PAGEDUMP=$(elinks --dump https://m.facebook.com/swp.de/?locale2=de_DE)
FBURLS=$(echo -e "$(echo "$PAGEDUMP" | grep lm.facebook.com | grep utm | sed -e 's/^.*u=//g' -e 's/%3Futm_medium.*$//' -e 's/%/\\x/g')" | uniq)

for FBURL in $FBURLS; do
	ARTICLEID=$(echo -e "$FBURL" | sed -e 's/^.*-\([0-9]*\)\.html$/\1/')
	PREVIOUSLINKNUMBER=$(echo -e "$PAGEDUMP" | grep $ARTICLEID | tail -n 1 | tr -d ' ' | awk -F '.' '{ print "\\[" $1-2 "\\]" }')
	LINKNUMBER=$(echo -e "$PAGEDUMP" | grep $ARTICLEID | tail -n 1 | tr -d ' ' | awk -F '.' '{ print "\\[" $1 "\\]" }')
#echo "ARTICLEID '$ARTICLEID'"
#echo "PREVIOUSLINKNUMBER '$PREVIOUSLINKNUMBER'"
#echo "LINKNUMBER '$LINKNUMBER'"
	#COMMENT=$(echo -e "$PAGEDUMP" | tr '\n' '#' | sed -e 's/^.*\['$PREVIOUSLINKNUMBER'\]/['$PREVIOUSLINKNUMBER']/' -e 's/\['$LINKNUMBER'\].*$//' -e 's/^.*swp.de## *//' -e 's/## */#/' | tr '#' '\n')
	COMMENT=$(echo -e "$PAGEDUMP" | tr '\n' '#' | sed -e 's/^.*'$PREVIOUSLINKNUMBER'/'$PREVIOUSLINKNUMBER'/' -e 's/'$LINKNUMBER'.*$//' -e 's/^.*swp.de## *//' -e 's/## */#/' -e 's/#*$//' | tr -s '#' ' ')
	# TODO check comment length
	TWEETSTRING="$COMMENT $FBURL"
	echo -e "$TWEETSTRING"
done
