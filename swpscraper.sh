#!/bin/bash

# source config
. ./swpscraper.config

# Path and file name for sqlite database
[ -z "$DBFILE" ] && DBFILE="/run/SWPDB"

# Path, file name, and parameters for command line Twitter client
[ -z "$TWITTER" ] && TWITTER="../oysttyer/oysttyer.pl -script"

# Page to be scraped:
[ -z "$BASEURL" ] && BASEURL="https://www.swp.de"

# Twitter handle to use
[ -z "BOTNAME" ] && BOTNAME="@SWPde_bot"

# Tweets will be prefaced with this string:
#[ -z "$PREFACE" ] && PREFACE=".@SWPde #SWP #SWPde "

if [ -n "$PREFACE" ] ; then
	PREFACE="$(echo "$PREFACE " | tr -s ' ')" # make sure there is exactly one trailing blank if $PREFACE wasn't empty
fi

# Lifesign message
[ -z "$LIFESIGN" ] && LIFESIGN=$(echo -e "\U0001f44b\U0001f916")

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

[ ${#NOISEARRAY[*]} -eq 0 ] && NOISEARRAY=( klick )

[ -z "$LOCATION" ] && LOCATION='Ulm,Deutschland'
[ -z "$CURRENTWEATHERMSG" ] && CURRENTWEATHERMSG="Das Wetter um"
[ -z "$SUNRISESUNSETMSG" ] && SUNRISESUNSETMSG="Sonnenauf- und -untergang heute"
[ -z "$TODAYSFORECASTMSG" ] && TODAYSFORECASTMSG="Die heutige Wettervorhersage inklusive Tageshöchst- und -tiefsttemperaturen"
[ -z "$FIVEDAYSFORECASTMSG" ] && FIVEDAYSFORECASTMSG="Die aktuelle 5-Tages-Wettervorhersage"
[ -z "$EXTERNALNEWSMSG" ] && EXTERNALNEWSMSG="Aktuelle Meldung"
[ -z "$NATIONALNEWSURLMSG" ] && NATIONALNEWSURLMSG="Überregionale Erwähnung unserer Stadt"
[ -z "$CITYGREP" ] && CITYGREP="Ulm\W|#Ulm"
[ -z "$EVENTSUGGESTIONMSG" ] && EVENTSUGGESTIONMSG="Wie wäre es mit ein paar Veranstaltungstipps"
[ -z "$ALTERNATETWITTERCREDENTIALSFILE" ] && ALTERNATETWITTERCREDENTIALSFILE=""

# some vars that need to be initialized here - don't touch
USERAGENT=${USERAGENTARRAY[$(($RANDOM%${#USERAGENTARRAY[*]}))]}
BACKOFF=0

function get_external_event_suggestion() {
	local STATUS
	local TIMESTAMP=$(date -d "$(date -d 'today' +%F)" +%s)
	local HUMANDATE=$(date +%x)
	local EVENTURLSARRAY=(
		'https://events.swp.de/ulm/veranstaltungen/veranstaltungen/?event[suche][pager]=&event[suche][kalender-tag]='"$TIMESTAMP"'&event[suche][mstmp]='"$TIMESTAMP"'&event[suche][stmpflag]=tag&event[suche][start]=0&event[suche][vwnum]=&event[suche][suchen]=0&event[suche][veranstalter]=&event[suche][land]=DE&event[suche][uhrzeit]=&event[suche][group]=&event[suche][ed_textsearch]=&event[suche][ressort]=0&event[suche][plz]=89073&event[suche][umkreis]=10&event[suche][zeitraum]=TAG&frmDatum='"$HUMANDATE"'&sf[seldat]='"$TIMESTAMP"
		'https://veranstaltungen.ulm.de/leoonline/portals/ulm/veranstaltungen/suche/neu/?search_from='"$HUMANDATE"
		'https://stadthaus.ulm.de/kalender'
		'http://www.ulmer-kalender.de/events/day/date/'"${HUMANDATE//-/.}"
			     )
	local EVENTSOURCEARRAY=(
			'aus dem Veranstaltungskalender der Südwest Presse (@SWPde)'
			'aus dem Veranstaltungskalender der Stadt Ulm (@ulm_donau)'
			'vom Stadthaus Ulm (@stadthaus_ulm)'
			'aus dem Veranstaltungskalender von Ulm-News (@ulmnews)'
			       )
	local EVENTTAGSARRAY=(
			'#SüdwestPresse #SWP #Veranstaltungskalender'
			'#StadtUlm #Stadt #Ulm #Veranstaltungskalender'
			'#StadthausUlm #Stadthaus #Ulm #Veranstaltungen'
			'#UlmNews #Ulm #Veranstaltungskalender'
			       )
	for EVENTURL in ${EVENTURLSARRAY[*]}; do
		# if not yet stored or entry older than today
		if [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM externalurls WHERE externalurl="'$EVENTURL'" LIMIT 1')" ] || \
			[ $(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM externalurls WHERE externalurl = "'$EVENTURL'" ORDER BY timestamp DESC LIMIT 1')" +%s) -lt $(date -d "$(date +%F)" +%s) ] ; then
			echo "$EVENTSUGGESTIONMSG ${EVENTSOURCEARRAY[$SOURCECOUNTER]}? ${EVENTTAGSARRAY[$SOURCECOUNTER]} $EVENTURL"
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO externalurls ('externalurl') VALUES ("'$EVENTURL'")'
			break
		fi
		SOURCECOUNTER=$((SOURCECOUNTER+1))
	done
}

function get_external_news_infos() {
	# TMC = Traffic Message Channel (https://en.wikipedia.org/wiki/Traffic_message_channel)
	local USERAGENT=$1
	local LISTNAME=$2
	local GREPSTRING=$3
	local TMC=$(scrape_page "$LISTNAME" "$USERAGENT" | grep -v "data-permalink-path" | grep '/status/' | sed -e 's/^.*a href="\([^"]*\)" class.*data-time="\([^"]*\)".*$/\2:\1/g')
	local STATUS
	for STATUS in $TMC; do
		local STATUSTIME=${STATUS%%:*}
		local STATUSPATH=${STATUS#*:}
		local SOURCE=$(echo $STATUSPATH | sed -e 's#^/\([^/]*\)/.*$#\1#g')
		local CUTOFFTIME=$(date -d '1 hour ago' +%s)
		if [ $STATUSTIME -gt $CUTOFFTIME ] && [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM externalurls WHERE externalurl="https://twitter.com'$STATUSPATH'" LIMIT 1')" ]; then
			if [ -n "$GREPSTRING" ] ; then
				PAGECONTENT=$(scrape_page "https://twitter.com${STATUSPATH}" "$USERAGENT")
				TITLESTRING=$(echo -e "$PAGECONTENT" | grep '<title>')
			fi
			if [ -z "$GREPSTRING" ] || echo -e "$TITLESTRING" | grep -q -Ew "$GREPSTRING" ; then 
				echo "$EXTERNALNEWSMSG (via @${SOURCE}): https://twitter.com${STATUSPATH}"
				sqlite3 $DBFILE 'INSERT OR REPLACE INTO externalurls ('externalurl') VALUES ("https://twitter.com$'$STATUSPATH'")'
				break
			fi
		fi
	done
}

function determine_last_tweet() {
	local USERAGENT=$1
	local TWEETTIME
	local SCRAPEDPAGE
	# we need to grab the first two entries and sort them, in case there is a pinned tweet
	SCRAPEDPAGE=$(scrape_page "https://twitter.com/${BOTNAME/@}" "$USERAGENT")
	TWEETTIME=$(date -d "@$(echo -e "$SCRAPEDPAGE" | grep 'class="tweet-timestamp' | sed -e 's/^.*data-time="\([^"]*\)".*$/\1/' | head -n 2 | sort -n | tail -n 1)" +%s)
	# we want to make sure a pinned tweet and a manually-sent tweet don't trigger a false positive, so head -n 3
	TWEETTITLES=$(echo -e "$SCRAPEDPAGE" | grep "TweetTextSize" | head -n 3)
	echo "${TWEETTIME}|${TWEETTITLES}"
}

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
	local TWEETEDLINK=0

	local SCRAPEDPAGE=$(scrape_page "$SINGLEURL" "$USERAGENT")

	# this is like placing an elephant in Africa (see https://paws.kettering.edu/~jhuggins/humor/elephants.html)
	if [ -z "$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'"')" ]; then
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastnewtweet")'
	fi

	if [ -n "$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'" AND already_tweeted = "false"')" ]; then
		# Determine publication/modification/page generation time
		PUBTIME=""
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '<meta http-equiv="last-modified" content="' | sed -e 's/^.*<meta http-equiv="last-modified" content="\([^"]*\)".*>.*$/\1/g')" +%s)\n"
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '<meta property="article:published_time" content="' | sed -e 's/^.*<meta property="article:published_time" content="\([^"]*\)".*>.*$/\1/g')" +%s)\n"
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '<meta property="article:modified_time" content="' | sed -e 's/^.*<meta property="article:modified_time" content="\([^"]*\)".*>.*$/\1/g')" +%s)\n"
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '"datePublished": "' | sed -e 's/^.*"datePublished": "\([^"]*\)".*$/\1/g')" +%s)\n"
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '"dateModified": "' | sed -e 's/^.*"dateModified": "\([^"]*\)".*$/\1/g')" +%s)\n"
		PUBTIME+="$(date -d "$(echo -e "$SCRAPEDPAGE" | grep '<!-- Generiert: ' | sed -e 's/^.*<!-- Generiert: \(.*\) -->.*$/\1/g')" +%s)\n"

		# Some more rules on when not to tweet:
		# Page contains '<meta property="og:type" content="video">' - this is a video-only page
		if echo -e "$SCRAPEDPAGE" | grep -q '<meta property="og:type" content="video">' ; then
			echo "Skipping '$SINGLEURL' - video-only page detected."
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page contains '<meta property="og:type" content="image">' - this is an image-gallery-only page
		elif echo -e "$SCRAPEDPAGE" | grep -q '<meta property="og:type" content="image">' ; then
			echo "Skipping '$SINGLEURL' - image-gallery-only page detected."
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page contains NEITHER '<div class="carousel' nor '<div class="image">' nor 'class="btn btn-primary more"' - this is probably a ticker-only page
		elif ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="carousel' && ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="image">' && ! echo -e "$SCRAPEDPAGE" | grep -q 'class="btn btn-primary more"' ; then
			echo "Skipping '$SINGLEURL' - no images at all detected in page, probably a ticker message."
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page timestamps are all older than 24h
		elif [ $(echo -e "$PUBTIME"| sort -un | tail -n 1) -lt $(date -d '-24 hours' +%s) ]; then
			echo "Skipping '$SINGLEURL' - all timestamps are older than 24h.  Slow news day, eh?"
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","skip")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		fi
	fi

	if [ -n "$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'" AND already_tweeted = "false"')" ]; then
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
				echo "About to tweet (in $RANDDELAY): '$MESSAGE' ($((${#TITLE}+24)) characters in total - link and preceding blank count as 24 chars)"
				sleep $RANDDELAY
				# so far, all command line twitter clients we tried out were dumb, and did not provide a return code in case of errors
				# that's why we need to perform a webscrape to check if our tweet went out
				echo "$MESSAGE" | eval "$TWITTER"
				RANDCHECKDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
				echo -n "Sleeping for $RANDCHECKDELAY to avoid false alerts when checking for tweet visibility ..."
				sleep $RANDCHECKDELAY
				LASTTWEET=$(determine_last_tweet "$USERAGENT")
				# I am aware that "$(echo $TITLE)" looks silly and pointless, but it doesn't work with "$TITLE", no idea why ...
				if (echo "$LASTTWEET" | grep -q "$(echo $TITLE)") ; then
					# Add entry to table
					echo -e " - Tweeted."
					sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","true")'
					sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastvisibletweet")'
					TWEETEDLINK=1
				else
					# unable to spot my own tweet!
					echo -e "\nError tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted."
					sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'
					sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastfailedtweet")'
					echo -e "--------------" >> swpscraper.error
					echo -e "$CHECKFORTWEET" >> swpscraper.error
					echo -e "--------------" >> swpscraper.error
					echo -e "$TITLE" >>swpscraper.error
					echo -e "--------------" >> swpscraper.error
					echo -e "$CHECKFORTWEET" | grep "$TITLE" >>swpscraper.error
					echo -e "--------------" >> swpscraper.error
					BACKOFF=1
				fi
			else
				sleep 1
				echo "Told to back off from tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted."
				sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'
				sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastbackedofftweet")'
			fi

		else 

			echo "priming URL table with '$SINGLEURL'"
			sleep 1 # this is so every entry has a unique timestamp
			# Add entry to table
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","true")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastprimedtweet")'
		fi

	else
		# This should update the timestamp so the entry is marked as recent and won't get purged
		TWEETSTATE="$(sqlite3 $DBFILE 'SELECT already_tweeted FROM swphomepage WHERE url="'$SINGLEURL'"')"
		sleep 1 # make sure timestamps are always at least 1s apart
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage (url,already_tweeted) VALUES ("'$SINGLEURL'","'$TWEETSTATE'")'
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastupdatedtweet")'
	fi

	echo "Done processing '$SINGLEURL'"

	if [ $BACKOFF -eq 1 ]; then
		echo "Setting BACKOFF."
		return 1
	else
		if [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM state WHERE status="lastlifesigncheck" ORDER BY timestamp DESC')" ] ; then
			# set flag that we've been here during this run
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastlifesigncheck")'
			# Determine last tweet time
			if ! ( [ $TWEETEDLINK -eq 1 ] | [ "$PRIMETABLE" = "yes" ] ) ; then
				if [ -z "$LASTTWEET" ] ; then
					local RANDLTTDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
					echo "Sleeping for $RANDLTTDELAY to avoid bot detection when checking for last visible tweet (lifesign check)"
					sleep $RANDLTTDELAY
					LASTTWEET=$(determine_last_tweet "$USERAGENT")
					# TODO FIXME do we have to call this somewhere here as well? sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastvisibletweet")'
				fi
				LTT=${LASTTWEET/|*}
				NOW=$(date -R)
				ONEHAGO=$(date -d "$NOW -1 hour" +%s)
				LASTLIFESIGNTWEETATTEMPT=$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastlifesigntweet" ORDER BY timestamp DESC LIMIT 1')
				if [ -z "$LASTLIFESIGNTWEETATTEMPT" ] ; then
					LASTLIFESIGNTWEETATTEMPTEPOCH=$(date -d "2 hours ago" +%s)
					echo "No Lifesign attempt found in DB."
				else
					LASTLIFESIGNTWEETATTEMPTEPOCH=$(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastlifesigntweet" ORDER BY timestamp DESC LIMIT 1')" +%s)
					echo "Lifesign attempt found in DB."
				fi
				#echo "Last Tweet Time: '$LTT'"
				#echo "Time one hour ago: '$ONEHAGO'"
				if [ $LTT -lt $ONEHAGO ] ; then
					echo "Last Tweet was more than 1 h ago (Tweet: '$(date -d "@$LTT" +%X)' | Now: '$(date -d "$NOW" +%X)')"
					if [ $LASTLIFESIGNTWEETATTEMPTEPOCH -lt $ONEHAGO ] ; then
						echo "Tweeting lifesign."
						CURRENTWEATHER=$(ansiweather -u metric -s true -a false -l "$LOCATION" -d true | sed -e 's/=>//g' -e 's/ - /\n/g')
						CW=$(echo -e "$CURRENTWEATHER" | awk '$0 ~ /Current weather in Ulm/ { $1=$2=$3=$4="" ; print $0 }')
						SUNRISE=$(echo -e "$CURRENTWEATHER" | awk '$0 ~/Sunrise/ { $1=""; print $0}')
						SUNSET=$(echo -e "$CURRENTWEATHER" | awk '$0 ~/Sunset/ { $1=""; print $0}')
						FIVEDAYFORECAST=$(ansiweather -f 6 -u metric -s true -a false -l "$LOCATION" -d true | sed -e 's/=>/\n/g' -e 's/ - /\n/g' | awk '$0 ~/°C/ { print $0 }')
						TODAYSFORECAST=$(echo -e "$FIVEDAYFORECAST" | awk -F':' '{ print $2 }' | head -n 1)
						CONVERTEDDATES=$(echo -e "$FIVEDAYFORECAST" | tail -n 5 | awk -F':' '{ print $1 }' | xargs -n 1 -I XXX date -d "XXX" +%d.%m.%y | tr '\n' ' ')
						CDA=($CONVERTEDDATES)
						REMAININGFORECAST=$(echo -e "$FIVEDAYFORECAST" | tail -n 5 | awk -F':' '{ print $2 }' | sed -e 's/ /_/g' -e 's/_$//g')
						RFA=($REMAININGFORECAST)
						FDFM="$FIVEDAYSFORECASTMSG"
						ONEBOT="$(echo -e '\U0001f916')"
						ONENOISE1="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
						ONENOISE2="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
						THREEBOTS="$(echo -e '\U0001f916\U0001f916\U0001f916')"
						THREENOISES1="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
						THREENOISES2="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
						# chatter
						TODAYEPOCH=$(date -d "$(date +%F)" +%s)
						LASTTODAYFORECASTTEPOCH=$(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lasttodayforecasttweet" ORDER BY timestamp DESC LIMIT 1')" +%s)
						LASTFIVEDAYSFORECASTTEPOCH=$(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastfivedaysforecasttweet" ORDER BY timestamp DESC LIMIT 1')" +%s)
						LASTSUNRISESUNSETEPOCH=$(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastsunrisesunsettweet" ORDER BY timestamp DESC LIMIT 1')" +%s)

						DEFAULTLIFESIGNLENGTH=${#LIFESIGN}
						LIFESIGNCOUNTER=0
						while [ ${#LIFESIGN} -eq $DEFAULTLIFESIGNLENGTH ] && [ $LIFESIGNCOUNTER -lt 10 ] ; do
							CHATTER=$((RANDOM%8))
							case $CHATTER in
								0)	# let's try today's weather forecast
									# due to time zone issues, weather forecasts don't work before 7am
									if [ $(date +%H) -lt 7 ] && [ -n "$LASTTODAYFORECASTEPOCH" ] && [ $LASTTODAYFORECASTEPOCH -gt $TODAYEPOCH ] ; then
											LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$TODAYSFORECASTMSG: $TODAYSFORECAST\n$ONEBOT $ONENOISE2 $ONEBOT"
											sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lasttodayforecasttweet")'
									fi
									;;
								1)	# let's try a five-day weather forecast
									if [ $(date +%H) -lt 7 ] && [ -n "$LASTFIVEDAYSFORECASTEPOCH" ] && [ $LASTFIVEDAYSFORECASTEPOCH -gt $TODAYEPOCH ]; then
											LIFESIGN="$THREEBOTS $THREENOISES1 $THREEBOTS\n$FDFM\n${CDA[0]}:${RFA[0]//_/ }\n${CDA[1]}:${RFA[1]//_/ }\n${CDA[2]}:${RFA[2]//_/ }"
											LIFESIGN+="\n${CDA[3]}:${RFA[3]//_/ }\n${CDA[4]}:${RFA[4]//_/ }\n$THREEBOTS $THREENOISES2 $THREEBOTS"
											sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastfivedayforecasttweet")'
									fi
									;;
								2)	# let's try unrise and sunset
									if [ -n "$LASTSUNRISESUNSETEPOCH" ] && [ $LASTSUNRISESUNSETEPOCH -gt $TODAYEPOCH ]; then
											LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$SUNRISESUNSETMSG: $(date -d "$SUNRISE" +%R)/$(date -d "$SUNSET" +%R)\n$ONEBOT $ONENOISE2 $ONEBOT"
											sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastsunrisesunsettweet")'
									fi
									;;
								3)	# let's show the current weather conditions
									LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$CURRENTWEATHERMSG $(date +"%x %X"): $CW\n$ONEBOT $ONENOISE2 $ONEBOT"
									;;
								4)	# let's try local news
									NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
									echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (local news list scraper)"
									sleep $NEWSSLEEP
									LISTNAME="https://twitter.com/${BOTNAME/@}/lists/news-l"
									EXTERNALLOCALNEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME")
									if [ -n "$EXTERNALLOCALNEWS" ] ; then
										echo "Tweeting latest external local news as lifesign."
										LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$EXTERNALLOCALNEWS"
									fi
									;;
								5)	# let's try competitor news
									NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
									echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (competitor news list scraper)"
									sleep $NEWSSLEEP
									LISTNAME="https://twitter.com/${BOTNAME/@}/lists/competition"
									COMPETITORNEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME" "$CITYGREP")
									if [ -n "$COMPETITORNEWS" ] ; then
										echo "Tweeting latest competitor news as lifesign."
										LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$COMPETITORNEWS"
									fi
									;;
								6)	# let's try nation-wide news
									NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
									echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (national news list scraper)"
									sleep $NEWSSLEEP
									LISTNAME="https://twitter.com/${BOTNAME/@}/lists/news-n"
									NATIONWIDENEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME" "$CITYGREP")
									if [ -n "$NATIONWIDENEWS" ] ; then
										echo "Tweeting last external national news as lifesign."
										LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$NATIONWIDENEWS"
									fi
									;;
								7)	# let's try local events
									EVENTSUGGESTION=$(get_external_event_suggestion)
									if [ -n "$EVENTSUGGESTION" ] ; then
										echo "Tweeting event suggestion as lifesign."
										LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$EVENTSUGGESTION"
									fi
									;;
								*)	# catch-all, just do nothing here
									# either we'll hit a working entry with the next iteration,
									# or we'll end up with the default chatter message
									: # NOP
									;;
							esac
						done
						# no luck, then use the default chatter message
						[ ${#LIFESIGN} -eq $DEFAULTLIFESIGNLENGTH ] && LIFESIGN+=" $(date +"%x %X")"
						echo -e "Lifesign message is: '$LIFESIGN'"

						eval "$TWITTER -status=\"$LIFESIGN\""
						sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastlifesigntweet")'
					else
						echo "Last attempt to tweet a lifesign was less than an hour ago, but it did not become visible.  Rate limiting suspected, backing off."
						return 1
					fi
				else
					echo "Last Tweet was less than 1 h ago (Tweet: '$(date -d "@$LTT" +%X)' | Now: '$(date -d "$NOW" +%X)').  No action needed."
				fi
			fi
		fi
		return 0
	fi
}

### BEGIN MAIN PROGRAM ###

# check if sqlite DB exists; if not, create it
if ! [ -f $DBFILE ] || [ -z "$(sqlite3 $DBFILE '.tables swphomepage')" ] ; then
	sqlite3 $DBFILE 'CREATE TABLE swphomepage (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, url data_type PRIMARY KEY, already_tweeted)'
fi
[ -z "$(sqlite3 $DBFILE '.tables state')" ] && sqlite3 $DBFILE 'CREATE TABLE state (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, status data_type PRIMARY KEY)'
[ -z "$(sqlite3 $DBFILE '.tables externalurls')" ] && sqlite3 $DBFILE 'CREATE TABLE externalurls (timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, externalurl data_type PRIMARY KEY)'

# this is to purge entries older than 14 days (to keep the database small)
sqlite3 $DBFILE 'delete from swphomepage where timestamp < datetime("now","-14 days")'
sqlite3 $DBFILE 'delete from externalurls where timestamp < datetime("now","-14 days")'

# reset lifesigncheck
sqlite3 $DBFILE 'DELETE FROM state WHERE status="lastlifesigncheck" LIMIT 1'

# check if table is empty, switch to priming mode if true
if [ -z "$(sqlite3 $DBFILE 'SELECT * FROM swphomepage ORDER BY timestamp DESC LIMIT 1')" ]; then
	echo 'URL table is empty, priming with content without tweeting'
	echo '(to avoid tweetstorm)'
	PRIMETABLE='yes'
else
	echo "Checking for postponed tweets ..."
	URLLIST=$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE already_tweeted ="false" ORDER BY timestamp ASC')
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
# sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime"),url FROM swphomepage ORDER BY timestamp'

# check for shadowban
if ! (lynx -dump 'https://twitter.com/search?f=tweets&vertical=default&q=from%3A%40'"${BOTNAME/@}"'&src=typd' | grep -A 1 -i "Search Results" | grep -q "$BOTNAME") ; then
	echo "No search results - have we been shadowbanned?"
fi


URLLIST=""
INITIALRANDSLEEP="$[ ( $RANDOM % 180 )  + 1 ]s"

# Saving this for another day ... check national news for a mention of Ulm and tweet this before scraping SWP?
#NATIONALLISTNAME="https://twitter.com/${BOTNAME/@}/lists/news-n"
#NATIONALNEWSURL=$(get_external_news_infos "$USERAGENT" "$NATIONALLISTNAME" "$CITYGREP")
#
#if [ -n "$NATIONALNEWSURL" ]; then
#		TWEETTHIS="$NATIONALNEWSURLMSG $NATIONALNEWSURL"
#fi


for SINGLEBASEURL in $BASEURL; do
	echo "Sleeping for $INITIALRANDSLEEP to avoid bot detection on '$SINGLEBASEURL'"
	sleep $INITIALRANDSLEEP

	# TODO maybe download raw html first and parse it with xmlstarlet?  Might allow for a more precise matching of which items should trigger a tweet and which should not
	# fetch URLLIST
	# URLs we should extract start with http and end with html
	# TODO replace lynx -dump with a tool that allows setting a referer, for faking a human surf experience
	if [ "$LINKTYPE" = "noticker" ] ; then
		# This should keep the update frequency down, as it will ignore the "ticker" on the front page, if pointed at the front page.
		URLLIST+="$(LANG=C lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly "$SINGLEBASEURL" 2>/dev/null | sed '0,/Hidden links:$/d' | awk ' $2 ~ /^http.*html$/ { print $2 }' )\n"
	elif [ "$LINKTYPE" = "tickeronly" ]; then
		# Alternatively, the following call will *only* tweet the "ticker" at the bottom of the front page
		# (however, it doesn't work for subpages like 'https://www.swp.de/suedwesten/staedte/ulm', so only use it for the front page)
		URLLIST+="$(lynx -useragent "$USERAGENT" -dump -hiddenlinks=ignore "$SINGLEBASEURL" | awk ' $2 ~ /^http.*html$/ { print $2 }')\n"
	else
		# Default: this will scrape all news from the page, including the "ticker" at the bottom of the front page, if pointed at the front page
		URLLIST+="$(lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly "$SINGLEBASEURL" 2>/dev/null | awk ' $2 ~ /^http.*html$/ { print $2 }')\n"
	fi
	#  [ -z "$FAKEREFERER" ] && FAKEREFERER=$SINGLEBASEURL # for future use - pretend user was following links from first page in list
	INITIALRANDSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s" # subsequent runs don't need such a long interval
done

URLLIST=$(echo -e "$URLLIST" | uniq )

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
	[ -n "$ALTERNATETWITTERCREDENTIALSFILE" ] && eval "$TWITTER -keyf=$ALTERNATETWITTERCREDENTIALSFILE -status='"$(echo -e '\U0001f916')"*krrrrk* Sand im Twittergetriebe *krrrrk*"$(echo -e '\U0001f916')"'"
	exit 1
else
	echo "Done."
	exit 0
fi

#### END MAIN PROGRAM ####
