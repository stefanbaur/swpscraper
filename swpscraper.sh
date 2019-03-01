#!/bin/bash

# source config
. ./swpscraper.config

# Page to be scraped:
[ -z "$BASEURL" ] && BASEURL="https://www.swp.de"

# Twitter handle to use
[ -z "BOTNAME" ] && BOTNAME="@SWPde_bot"

# Tweets will be prefaced with this string:
#[ -z "$PREFACE" ] && PREFACE=".@SWPde #SWP #SWPde "

if [ -n "$PREFACE" ] ; then
	PREFACE="$(echo "$PREFACE " | tr -s ' ')" # make sure there is exactly one trailing blank if $PREFACE wasn't empty
fi

# List of fake user agents to further avoid bot detection
[ ${#USERAGENTARRAY[*]} -eq 0 ] && \
USERAGENTARRAY=('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:65.0) Gecko/20100101 Firefox/65.0' \
		'Google Chrome Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36' \
		'Mozilla Firefox Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0' \
		'Mozilla/5.0 (compatible, MSIE 11, Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko' \
		'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393' \
		'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0' \
		'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
		'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.3 Safari/605.1.15' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.2 Safari/605.1.15' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' \
		'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:65.0) Gecko/20100101 Firefox/65.0' \
		'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36' 
		)

[ -z "$LINKTYPE" ] && LINKTYPE="fullpage"

# Example Black- and Whitelist entries that may be placed in swpscraper.config
# BLACKLIST="^https://www.swp.de/panorama/|^https://www.swp.de/sport/"
# WHITELIST="^https://www.swp.de/suedwesten/staedte/ulm/|^https://www.swp.de/suedwesten/staedte/neu-ulm/|^https://www.swp.de/suedwesten/landkreise/kreis-neu-ulm-bayern/|^https://www.swp.de/suedwesten/landkreise/alb-donau/"

# some vars that need to be initialized here - don't touch
USERAGENT=${USERAGENTARRAY[$(($RANDOM%${#USERAGENTARRAY[*]}))]}
BACKOFF=0

function scrape_page() {

	local URL=$1
	local USERAGENT=$2
	local SCRAPEDPAGE=""

	SCRAPEDPAGE=$(wget -q -U "$USERAGENT" -O - "$URL")
	echo -e "$SCRAPEDPAGE"

}

function tweet_and_update() {

	local SINGLEURL=$1
	local USERAGENT=$2
	local BACKOFF=$3
	local PRIMETABLE=$4

	local SCRAPEDPAGE=$(scrape_page "$SINGLEURL" "$USERAGENT")

	# this is like placing an elephant in Africa (see https://paws.kettering.edu/~jhuggins/humor/elephants.html)
	if [ -z "$(sqlite3 SWPDB 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'"')" ]; then
		sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'
	fi

	if [ -n "$(sqlite3 SWPDB 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'" AND already_tweeted = "false"')" ]; then

		# Three more rules on when not to tweet:
		# Page contains '<meta property="og:type" content="video">' - this is a video-only page
		if echo -e "$SCRAPEDPAGE" | grep -q '<meta property="og:type" content="video">' ; then
			echo "Skipping '$SINGLEURL' - video-only page detected."
			sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'

		# Page contains '<meta property="og:type" content="image">' - this is an image-gallery-only page
		elif echo -e "$SCRAPEDPAGE" | grep -q '<meta property="og:type" content="image">' ; then
			echo "Skipping '$SINGLEURL' - image-gallery-only page detected."
			sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'

		# Page contains NEITHER '<div class="carousel' nor '<div class="image">' - this is probably a ticker-only page
		elif ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="carousel' && ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="image">' ; then
			echo "Skipping '$SINGLEURL' - no images at all detected in page, probably a ticker message."
			sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'
		fi
	fi

	if [ -n "$(sqlite3 SWPDB 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'" AND already_tweeted = "false"')" ]; then
		# TODO IMPORTANT TITLE needs to be sanitized as well - open to suggestions on how to improve the whitelisting here ...
		# still needs support for accents on letters and similar foo
		# never (unless you want hell to break loose) allow \"'$
		# allowing € leads to allowing UTF-8 in general, it seems? At least tr doesn't see a difference between € and –, which is dumb
		# TODO FIXME: a "." preceded and followed by at least two non-whitespace characters needs a whitespace inserted right after it, or else twitter might try to turn it into an URL
		TITLE=$(echo -e "$SCRAPEDPAGE" | grep '<.*title>' | tr -d '\n' | tr -s ' ' | sed -e 's/^.*<title>\(.*\)\w*|.*$/\1/' -e 's/–/-/' -e 's/&quot;\(.*\)&quot;/„\1“/g' -e 's/&amp;/\&/g' -e 's/[^a-zA-Z0-9äöüÄÖÜß%€„“ _/.,!?&():=-]/ /g')
		if [ -n "$TITLE" ] ; then
			TITLE="$(echo "$TITLE " | tr -s ' ')" # make sure there is exactly one trailing blank if $TITLE wasn't empty
		fi

		if ! [ "$PRIMETABLE" = "yes" ]; then

			# IMPORTANT: Update times should be randomized within a 120-180 second interval (to work around twitter's bot/abuse detection and API rate limiting)
			RANDDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"

			TITLE="${PREFACE}${TITLE}"
			# Message length needs to be truncated to 280 chars without damaging the link
			# required chars for link: 23 chars + 1 blank  (current shortlink size enforced by twitter)
			MAXTITLELENGTH=$((280-23-1))
			if [ $MAXTITLELENGTH -lt ${#TITLE} ]; then
				echo -n "Truncating message '$TITLE' to "
				TITLE="${TITLE:0:$((MAXTITLELENGTH-4))} ..."
				echo "'$TITLE' due to tweet length limit, so that shortlink will still fit."
			fi

			# compose message
			MESSAGE="${TITLE}${SINGLEURL}"

			if [ $BACKOFF -eq 0 ]; then
				echo -n "About to tweet (in $RANDDELAY): '$MESSAGE' ($((${#TITLE}+24)) characters in total - link and preceding blank count as 24 chars)"
				sleep $RANDDELAY
				# oystter is dumb, no return code either
				echo "$MESSAGE" | ../oysttyer/oysttyer.pl -script
				RANDCHECKDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
				echo "Sleeping for $RANDCHECKDELAY to avoid false alerts when checking for tweet visibility"
				sleep $RANDCHECKDELAY
				# if ! echo '/again '"$BOTNAME" | ../oysttyer/oysttyer.pl -script | grep -q "$TITLE" ; then 
				# trying this instead, maybe it helps us stay below the rate limit ...
				if ! wget -O - "https://twitter.com/$BOTNAME" | grep -q "$TITLE" ; then
					# unable to spot my own tweet!
					echo -e "\nError tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted. RetCode was: '$RETCODE'"
					sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'

					BACKOFF=1
				else
					# Add entry to table
					echo -e " - Tweeted."
					sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","true")'

				fi
			else
				sleep 1
				echo "Told to back off from tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted."
				sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'

			fi

		else 

			echo "priming URL table with '$SINGLEURL'"
			sleep 1 # this is so every entry has a unique timestamp
			# Add entry to table
			sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","true")'

		fi

	else
		# This should update the timestamp so the entry is marked as recent and won't get purged
		TWEETSTATE="$(sqlite3 SWPDB 'SELECT already_tweeted FROM swphomepage WHERE url="'$SINGLEURL'"')"
		sleep 1 # make sure timestamps are always at least 1s apart
		sqlite3 SWPDB 'INSERT OR REPLACE INTO swphomepage (url,already_tweeted) VALUES ("'$SINGLEURL'","'$TWEETSTATE'")'
	fi

	if [ $BACKOFF -eq 1 ]; then
		echo "Setting BACKOFF."
		return 1
	else
		return 0
	fi
}

### BEGIN MAIN PROGRAM ###

# check if sqlite DB exists; if not, create it
if ! [ -f SWPDB ] ; then
	 sqlite3 SWPDB 'CREATE TABLE swphomepage (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, url data_type PRIMARY KEY, already_tweeted)'
fi

# this is to purge entries older than 14 days (to keep the database small)
sqlite3 SWPDB 'delete from swphomepage where timestamp < datetime("now","-14 days")'

# check if table is empty, switch to priming mode if true
if [ -z "$(sqlite3 SWPDB 'SELECT * FROM swphomepage ORDER BY timestamp DESC LIMIT 1')" ]; then
	echo 'URL table is empty, priming with content without tweeting'
	echo '(to avoid tweetstorm)'
	PRIMETABLE='yes'
else
	echo "Checking for postponed tweets ..."
	URLLIST=$(sqlite3 SWPDB 'SELECT url FROM swphomepage WHERE already_tweeted ="false" ORDER BY timestamp DESC')
	BACKOFF=0
	for SINGLEURL in $URLLIST; do
		tweet_and_update "$SINGLEURL" "$USERAGENT" "$BACKOFF" || BACKOFF=1
	done
	echo "Done checking for postponed tweets."

	if [ $BACKOFF -eq 1 ]; then
		echo "Looks like we're still tweeting too much, exiting."
		exit 1
	fi
fi

# to look at the database content, run:
# sqlite3 SWPDB 'SELECT datetime(timestamp,"localtime"),url FROM swphomepage ORDER BY timestamp'

INITIALRANDSLEEP="$[ ( $RANDOM % 180 )  + 1 ]s"
echo "Sleeping for $INITIALRANDSLEEP to avoid bot detection on '$BASEURL'"
sleep $INITIALRANDSLEEP

# TODO maybe download raw html first and parse it with xmlstarlet?  Might allow for a more precise matching of which items should trigger a tweet and which should not
# fetch URLLIST
# URLs we should extract start with http and end with html

if [ "$LINKTYPE" = "noticker" ] ; then
	# This should keep the update frequency down, as it will ignore the "ticker" on the front page, if pointed at the front page.
	URLLIST=$(LANG=C lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly $BASEURL 2>/dev/null | sed '0,/Hidden links:$/d' | awk ' $2 ~ /^http.*html$/ { print $2 }' | uniq -u )
elif [ "$LINKTYPE" = "tickeronly" ]; then
	# Alternatively, the following call will *only* tweet the "ticker" at the bottom of the front page
	# (however, it doesn't work for subpages like 'https://www.swp.de/suedwesten/staedte/ulm', so only use it for the front page)
	URLLIST=$(lynx -useragent "$USERAGENT" -dump -hiddenlinks=ignore $BASEURL | awk ' $2 ~ /^http.*html$/ { print $2 }' | uniq -u )
else
	# Default: this will scrape all news from the page, including the "ticker" at the bottom of the front page, if pointed at the front page
	URLLIST=$(lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly $BASEURL 2>/dev/null | awk ' $2 ~ /^http.*html$/ { print $2 }' | uniq -u )
fi

if [ -n "$WHITELIST" ]; then
	# aggressive filtering: whitelisted link destinations
	URLLIST=$(echo -e "$URLLIST" | grep -E "$WHITELIST" )
elif [ -n "$BLACKLIST" ]; then
	# less aggressive filtering: blacklisted link destinations
	URLLIST=$(echo -e "$URLLIST" | grep -v -E "$BLACKLIST" )
else
	: # NOP
fi

for SINGLEURL in $URLLIST; do

	# IMPORTANT: String must be filtered for valid chars to block SQL injection and shell injection
	SINGLEURL=$(echo $SINGLEURL | tr -d -c 'a-zA-Z0-9_/.:-') # SWP only uses this character subset in their URLs

	if [ -n "$SINGLEURL" ] ; then
		if ! tweet_and_update "$SINGLEURL" "$USERAGENT" "$BACKOFF" "$PRIMETABLE" ; then
			BACKOFF=1
		fi
	else
		# does for even start when $URLLIST is empty?
		echo "Not a single URL found."
	fi
done

if [ $BACKOFF -eq 1 ]; then
	echo "Backed off due to errors."
	exit 1
else
	echo "Done."
	exit 0
fi

#### END MAIN PROGRAM ####
