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
# some vars that need to be initialized here - don't touch
#USERAGENT # elinks does not support overriding the user agent string via command line
BACKOFF=0

PAGEDUMP=$(elinks --dump https://m.facebook.com/swp.de/?locale2=de_DE)
FBURLS=$(echo -e "$(echo "$PAGEDUMP" | grep lm.facebook.com | grep utm | sed -e 's/^.*u=//g' -e 's/%3Futm_medium.*$//' -e 's/%/\\x/g')" | uniq)

### BEGIN MAIN PROGRAM ###

# check if sqlite DB exists; if not, create it
if ! [ -f $DBFILE ] || [ -z "$(sqlite3 $DBFILE '.tables swphomepage')" ] ; then
	sqlite3 $DBFILE 'CREATE TABLE swphomepage (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, url data_type PRIMARY KEY, already_tweeted)'
fi
# make sure table swphomepage has a "reason" column
if ! sqlite3 $DBFILE 'PRAGMA table_info(swphomepage)' | grep -q '|reason|'; then
	sqlite3 $DBFILE 'ALTER TABLE swphomepage ADD COLUMN reason'
fi

# this is to purge entries older than 8 days (to keep the database small)
sqlite3 $DBFILE 'delete from swphomepage where timestamp < datetime("now","-8 days")'
# check if table is empty, switch to priming mode if true
if [ -z "$(sqlite3 $DBFILE 'SELECT * FROM swphomepage ORDER BY timestamp DESC LIMIT 1')" ]; then
	echo 'URL table is empty, priming with content without tweeting'
	echo '(to avoid tweetstorm)'
	PRIMETABLE='yes'
else
	echo "Checking for postponed tweets ..."
	URLLIST=$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE already_tweeted ="false" ORDER BY timestamp ASC')
	BACKOFF=-1
	for SINGLEURL in $URLLIST; do
		tweet_and_update "$SINGLEURL" "$USERAGENT" "$BACKOFF" || BACKOFF=1
	done
	echo "Done checking for postponed tweets."

	if [ $BACKOFF -eq 1 ]; then
		echo "Looks like we're still tweeting too much, exiting."
		exit 1
	fi
fi

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
