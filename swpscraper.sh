#!/bin/bash

# source config
. ./swpscraper.config

# Path and file name for sqlite database
[ -z "$DBFILE" ] && DBFILE="/run/SWPDB"

# TempDir
[ -z "$TEMPDIR" ] && TEMPDIR="/tmp/"

# Path, file name, and parameters for command line Twitter client
[ -z "$TWITTER" ] && TWITTER="../tweepy/tweet-via-tweepy.py"

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

# some vars that need to be initialized here - don't touch
USERAGENT=${USERAGENTARRAY[$(($RANDOM%${#USERAGENTARRAY[*]}))]}
BACKOFF=0

function get_external_event_suggestion() {
	local STATUS
	local TIMESTAMP=$(date -d "$(date -d 'today' +%F)" +%s)
	local HUMANDATE=$(date +%x)
	local ISODATE=$(date +%F)
	local EVENTURLSARRAY=(
		'https://events.swp.de/ulm/veranstaltungen/veranstaltungen/?event[suche][pager]=&event[suche][kalender-tag]='"$TIMESTAMP"'&event[suche][mstmp]='"$TIMESTAMP"'&event[suche][stmpflag]=tag&event[suche][start]=0&event[suche][vwnum]=&event[suche][suchen]=0&event[suche][veranstalter]=&event[suche][land]=DE&event[suche][uhrzeit]=&event[suche][group]=&event[suche][ed_textsearch]=&event[suche][ressort]=0&event[suche][plz]=89073&event[suche][umkreis]=10&event[suche][zeitraum]=TAG&frmDatum='"$HUMANDATE"'&sf[seldat]='"$TIMESTAMP"
		'https://veranstaltungen.ulm.de/leoonline/portals/ulm/veranstaltungen/suche/neu/?search_from='"$HUMANDATE"
		'https://stadthaus.ulm.de/kalender'
		'http://www.ulmer-kalender.de/events/day/date/'"${HUMANDATE//-/.}"
		'https://www.regioactive.de/events/25209/ulm/veranstaltungen-party-konzerte/'"$ISODATE"
		'https://veranstaltungen.meinestadt.de/ulm'
		'https://www.donau3fm.de/events'
		'https://www.theater-ulm.de/spielplan'
		'http://theater-neu-ulm.de/cmsroot/spielplan/'
		'http://www.frizz-ulm.de/events/'
		'https://www.uni-ulm.de/home/sitemap/kalender/'
		'http://ulm.partyphase.net/veranstaltungskalender-ulm/'

			     )
	local EVENTSOURCEARRAY=(
			'aus dem Veranstaltungskalender der Südwest Presse (@SWPde)'
			'aus dem Veranstaltungskalender der Stadt Ulm (@ulm_donau)'
			'vom Stadthaus Ulm (@stadthaus_ulm)'
			'aus dem Veranstaltungskalender von Ulm-News (@ulmnews)'
			'aus dem Veranstaltungskalender von regioactive (@regioactive)'
			'aus dem Veranstaltungskalender von meinestadt․de (@meinestadt_de)'
			'aus dem Veranstaltungskalender von Donau 3 FM (@donau3fm)'
			'aus dem Spielplan des Theaters Ulm (@TheaterUlm)'
			'aus dem Spielplan des Theaters Neu-Ulm (AuGuSTheater)'
			'aus dem Veranstaltungskalender von Frizz Ulm'
			'aus dem Veranstaltungskalender der Universität Ulm (@uni_ulm)'
                        'aus dem Veranstaltungskalender von Partyphase (@partyphase)'
			       )
	local EVENTTAGSARRAY=(
			'#SüdwestPresse #SWP #Veranstaltungskalender'
			'#StadtUlm #Stadt #Ulm #Veranstaltungskalender'
			'#StadthausUlm #Stadthaus #Ulm #Veranstaltungen'
			'#UlmNews #Ulm #Veranstaltungskalender'
			'#regioactive #Ulm #Veranstaltungskalender'
			'#meinestadt_de #meinestadtde #meinestadt #Ulm #Veranstaltungskalender'
			'#donau3fm #donau3 #Ulm #Veranstaltungskalender'
			'#TheaterUlm #Theater #Ulm #Spielplan'
			'#TheaterNeuUlm #Theater #NeuUlm #AuGuSTheater #Spielplan'
			'#FrizzUlm #Frizz #Ulm #Veranstaltungskalender'
			'#UniversitaetUlm #UniUlm #Ulm #Veranstaltungskalender'
			'#PartyphaseUlm #Partyphase #Ulm #Veranstaltungskalender'
			       )
	for EVENTURL in ${EVENTURLSARRAY[*]}; do
		# if not yet stored or entry older than today
		if [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM externalurls WHERE externalurl="'$EVENTURL'" LIMIT 1')" ] || \
# TODO add a randomizer and 12h block here
			[ $(date -d "$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM externalurls WHERE externalurl = "'$EVENTURL'" ORDER BY timestamp DESC LIMIT 1')" +%s) -lt $(date -d "$(date +%F)" +%s) ] ; then
			echo "$EVENTSUGGESTIONMSG ${EVENTSOURCEARRAY[$SOURCECOUNTER]}? ${EVENTTAGSARRAY[$SOURCECOUNTER]} $EVENTURL"
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO externalurls ('externalurl') VALUES ("'$EVENTURL'")'
			break
		fi
		SOURCECOUNTER=$((SOURCECOUNTER+1))
	done
}

# TODO this might still be broken regarding scrape_swp_page vs. scrape_twitter_page, needs check
function get_external_news_infos() {
	# TMC = Traffic Message Channel (https://en.wikipedia.org/wiki/Traffic_message_channel)
	local USERAGENT=$1
	local LISTNAME=$2
	local GREPSTRING=$3
	local TMC=$(scrape_swp_page "$LISTNAME" "$USERAGENT" | grep -v "data-permalink-path" | grep '/status/' | sed -e 's/^.*a href="\([^"]*\)" class.*data-time="\([^"]*\)".*$/\2:\1/g')
	local STATUS
	for STATUS in $TMC; do
		local STATUSTIME=${STATUS%%:*}
		local STATUSPATH=${STATUS#*:}
		local SOURCE=$(echo $STATUSPATH | sed -e 's#^/\([^/]*\)/.*$#\1#g')
		local CUTOFFTIME=$(date -d '1 hour ago' +%s)
		if [ $STATUSTIME -gt $CUTOFFTIME ] && [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM externalurls WHERE externalurl="https://twitter.com'$STATUSPATH'" LIMIT 1')" ]; then
			if [ -n "$GREPSTRING" ] ; then
				PAGECONTENT=$(scrape_swp_page "https://twitter.com${STATUSPATH}" "$USERAGENT")
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
	local LONGCHECK=$2
	local TWEETTIME
	local TWEETTIMESTAMP
	local TWEETTIMESTAMPS=""
	local SCRAPEDPAGE
	# we need to grab the first two entries and sort them, in case there is a pinned tweet
	SCRAPEDPAGE=$(scrape_twitter_page "https://nitter.net/${BOTNAME/@}" "$USERAGENT")
	TWEETTIMES="$(echo -e "$SCRAPEDPAGE" | grep 'class="tweet-date' | sed -e 's/^.*title="\([^"]*\)".*$/\1|/' -e 's/ · / /')"
	
	OLDIFS=$IFS; IFS="|"
	for TWEETTIMESTAMP in $TWEETTIMES; do 
		TWEETTIMESTAMPS=$(echo -e "$TWEETTIMESTAMPS\n$(date -d "$TWEETTIMESTAMP" +%s)\n")
	done
	IFS=$OLDIFS 
	TWEETTIME=$(echo -e "TWEETTIMESTAMPS" | sort -n | tail -n 1)
	if [ -n "$LONGCHECK" ]; then
		# Let's dump all we have
		TWEETTITLES=$(echo -e "$SCRAPEDPAGE" | grep "tweet-content media-body")
	else
		# we want to make sure a pinned tweet and a manually-sent tweet don't trigger a false positive, so head -n 3
		TWEETTITLES=$(echo -e "$SCRAPEDPAGE" | grep "tweet-content media-body" | head -n 3)
	fi
	echo "${TWEETTIME}|${TWEETTITLES}"
}

function already_tweeted() {
	local LASTTWEET=$1
	local TITLE=$2
	local SINGLEURL=$3
	## I am aware that "$(echo $TITLE)" looks silly and pointless, but it doesn't work with "$TITLE", no idea why ...
	#if (echo "$LASTTWEET" | sed  -e 's/&amp;/\&/g' | grep -q "$(echo $TITLE)") ; then
	if (echo "$LASTTWEET" | grep -q "$SINGLEURL") ; then
		# Mark as tweeted
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","true")'
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastvisibletweet")'
		return 0
	else
		# Mark as not yet tweeted
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted') VALUES ("'$SINGLEURL'","false")'
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastfailedtweet")'
		return 1
	fi
}

function scrape_swp_page() {

	local URL=$1
	local USERAGENT=$2
	local SCRAPEDPAGE=""

	SCRAPEDPAGE=$(timeout 60 wget -q -U "$USERAGENT" -O - "$URL")
	echo -e "$SCRAPEDPAGE"

}

function scrape_twitter_page() {

	local URL=$1
	local USERAGENT=$2
	local SCRAPEDPAGE=""

	#SCRAPEDPAGE=$(timeout 60 wget -q -U "$USERAGENT" --post-data="" -O - --referer "$URL" "https://mobile.twitter.com/i/nojs_router?path=%2F${URL##*/}")
	SCRAPEDPAGE=$(wget -q -U "$USERAGENT" -O - "$URL")
	echo -e "$SCRAPEDPAGE"

}

function heartbeat() {
	# TWEETEDLINK aus DB auslesen/setzen
	local TWEETEDLINK
	local USERAGENT=$1
	local PRIMETABLE=$2
	local LASTTWEETDB
	local LASTTWEET
	local LTT
	local NOW
	local ONEHAGO
		if [ -z "$(sqlite3 $DBFILE 'SELECT timestamp FROM state WHERE status="lastlifesigncheck" ORDER BY timestamp DESC')" ] ; then
		# set flag that we've been here during this run
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastlifesigncheck")'
		# Determine last tweet time
		if !  [ "$PRIMETABLE" = "yes" ] ; then
			# Note that the blank *after* the " is important! date will throw an error if the result of $(...) is empty and there is no blank in the "" ...
			LASTTWEETDB=$(date -d " $(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status="lastvisibletweet" ORDER BY timestamp DESC')" +%s)
			NOW=$(date -R)
			ONEHAGO=$(date -d "$NOW -1 hour" +%s)
			#echo "Last Tweet Time according to DB: '$LASTTWEETDB'"
			#echo "Time one hour ago: '$ONEHAGO'"
			if [ $LASTTWEETDB -lt $ONEHAGO ] ; then
				echo "Last logged regular Tweet (not counting lifesigns) was more than 1 h ago (Tweet in DB: '$(date -d "@$LASTTWEETDB" +%X)' | Now: '$(date -d "$NOW" +%X)')"
				echo "Determining timestamp of last visible tweet ..."
				LASTTWEET=$(determine_last_tweet "$USERAGENT")
				LTT=${LASTTWEET/|*}
				if [ $LASTTWEETDB -lt $LTT ] ; then
					echo "Updating timestamp to timestamp of actual last visible tweet ($(date -d "@$LTT" +"%F %X"))"
					sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('timestamp','status') VALUES (datetime("'$LTT'","unixepoch"),"lastvisibletweet")'
				fi

			else
				LTT=$LASTTWEETDB
			fi
			if [ $LTT -lt $ONEHAGO ] ; then
				echo "Last visible Tweet was more than 1 h ago (Tweet: '$(date -d "@$LTT" +%X)' | Now: '$(date -d "$NOW" +%X)')"
				echo "Tweeting lifesign."
				local CURRENTWEATHER=$(ansiweather -u metric -s true -a false -l "$LOCATION" -d true | sed -e 's/=>//g' -e 's/ - /\n/g')
				local CW=$(echo -e "$CURRENTWEATHER" | awk '$0 ~ /Current weather in Ulm/ { $1=$2=$3=$4="" ; print $0 }')
				local SUNRISE=$(echo -e "$CURRENTWEATHER" | awk '$0 ~/Sunrise/ { $1=""; print $0}')
				local SUNSET=$(echo -e "$CURRENTWEATHER" | awk '$0 ~/Sunset/ { $1=""; print $0}')
				local FIVEDAYFORECAST=$(ansiweather -f 6 -u metric -s true -a false -l "$LOCATION" -d true | sed -e 's/=>/\n/g' -e 's/ - /\n/g' | awk '$0 ~/°C/ { print $0 }')
				local TODAYSFORECAST=$(echo -e "$FIVEDAYFORECAST" | awk -F':' '{ print $2 }' | head -n 1)
				local CONVERTEDDATES=$(echo -e "$FIVEDAYFORECAST" | tail -n 5 | awk -F':' '{ print $1 }' | xargs -n 1 -I XXX date -d "XXX" +%d.%m.%y | tr '\n' ' ')
				local CDA=($CONVERTEDDATES)
				local REMAININGFORECAST=$(echo -e "$FIVEDAYFORECAST" | tail -n 5 | awk -F':' '{ print $2 }' | sed -e 's/ /_/g' -e 's/_$//g')
				local RFA=($REMAININGFORECAST)
				local FDFM="$FIVEDAYSFORECASTMSG"
				local ONEBOT="$(echo -e '\U0001f916')"
				local ONENOISE1="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
				local ONENOISE2="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
				local THREEBOTS="$(echo -e '\U0001f916\U0001f916\U0001f916')"
				local THREENOISES1="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
				local THREENOISES2="*${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}* *${NOISEARRAY[$((RANDOM%NOISEAMOUNT))]}*"
				# chatter
				local TODAYEPOCH=$(date -d "$(date +%F)" +%s)
				local THREEHOURSAGOEPOCH=$(date -d '-3 hours' +%s)
				local LASTTODAYFORECASTEPOCHDB=$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lasttodayforecasttweet" ORDER BY timestamp DESC LIMIT 1')
				if [ -n "$LASTTODAYFORECASTEPOCHDB" ] ; then
					local LASTTODAYFORECASTEPOCH=$(date -d "$LASTTODAYFORECASTEPOCHDB" +%s)
				else
					local LASTTODAYFORECASTEPOCH=""
				fi
				local LASTFIVEDAYSFORECASTEPOCHDB=$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastfivedaysforecasttweet" ORDER BY timestamp DESC LIMIT 1')
				if [ -n "$LASTFIVEDAYSFORECASTEPOCHDB" ] ; then
					local LASTFIVEDAYSFORECASTEPOCH=$(date -d "$LASTFIVEDAYSFORECASTEPOCHDB" +%s)
				else
					local LASTFIVEDAYSFORECASTEPOCH=""
				fi
				local LASTSUNRISESUNSETEPOCHDB=$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lastsunrisesunsettweet" ORDER BY timestamp DESC LIMIT 1')
				if [ -n "$LASTSUNRISESUNSETEPOCHDB" ] ; then
					local LASTSUNRISESUNSETEPOCH=$(date -d "$LASTSUNRISESUNSETEPOCHDB" +%s)
				else
					local LASTSUNRISESUNSETEPOCH=""
				fi
				local LASTEVENTSEPOCHDB=$(sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime") FROM state WHERE status = "lasteventstweet" ORDER BY timestamp DESC LIMIT 1')
				if [ -n "$LASTEVENTSEPOCHDB" ] ; then
					local LASTEVENTSEPOCH=$(date -d "$LASTEVENTSEPOCHDB" +%s)
				else
					local LASTEVENTSEPOCH=""
				fi

				local DEFAULTLIFESIGNLENGTH=${#LIFESIGN}
				local LIFESIGNCOUNTER=0
				while [ ${#LIFESIGN} -eq $DEFAULTLIFESIGNLENGTH ] && [ $LIFESIGNCOUNTER -lt 10 ] ; do
					local CHATTER=$((RANDOM%7))
					# local CHATTER=$(timeout 60 wget -q -O - 'http://www.miraclesalad.com/webtools/random.php?i=1&u=1&low=1&high=6&groups=1&Submit=Go' | grep '<p class="output">' | awk -F'>|<' '{ print $3}' | tr -d -c '[:digit:]')
					echo "CHATTER: '$CHATTER'"
					case $CHATTER in
						0)	# let's try today's weather forecast
							# due to time zone issues, weather forecasts don't work before 7am
							if [ $(date +%H) -gt 7 ] && ( [ -z "$LASTTODAYFORECASTEPOCH" ] || [ $LASTTODAYFORECASTEPOCH -lt $TODAYEPOCH ] ); then
									LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$TODAYSFORECASTMSG: $TODAYSFORECAST\n$ONEBOT $ONENOISE2 $ONEBOT"
									sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lasttodayforecasttweet")'
							else
								echo 'Unable to use weather forecast of today.'
								echo "Current hour: '$(date +%H)'"
								if [ $(date +%H) -gt 7 ] ; then
									echo "Current hour was greater than 7"
								else
									echo "Current hour was less than 7"
								fi
								echo "LASTTODAYFORECASTEPOCH: '$LASTTODAYFORECASTEPOCH'"
								if [ -n "$LASTTODAYFORECASTEPOCH" ] ; then
									echo  'LASTTODAYFORECASTEPOCH was not empty.'
								fi
								echo "TODAYEPOCH: '$TODAYEPOCH'"
								if [ $LASTTODAYFORECASTEPOCH -lt $TODAYEPOCH ] ; then
									echo 'LASTTODAYFORECASTEPOCH was less than TODAYEPOCH'
								else
									echo 'LASTTODAYFORECASTEPOCH was more than TODAYEPOCH'
								fi
							fi
							;;
						1)	# let's try a five-day weather forecast
							if [ $(date +%H) -gt 7 ] && ( [ -z "$LASTFIVEDAYSFORECASTEPOCH" ] || [ $LASTFIVEDAYSFORECASTEPOCH -lt $TODAYEPOCH ] ); then
									LIFESIGN="$THREEBOTS $THREENOISES1 $THREEBOTS\n$FDFM\n${CDA[0]}:${RFA[0]//_/ }\n${CDA[1]}:${RFA[1]//_/ }\n${CDA[2]}:${RFA[2]//_/ }"
									LIFESIGN+="\n${CDA[3]}:${RFA[3]//_/ }\n${CDA[4]}:${RFA[4]//_/ }\n$THREEBOTS $THREENOISES2 $THREEBOTS"
									sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastfivedaysforecasttweet")'
							else
								echo 'Unable to use five-day weather forecast.'
								echo "Current hour: '$(date +%H)'"
								if [ $(date +%H) -gt 7 ] ; then
									echo "Current hour was greater than 7"
								else
									echo "Current hour was less than 7"
								fi
								echo "LASTFIVEDAYSFORECASTEPOCH: '$LASTFIVEDAYSFORECASTEPOCH'"
								if [ -n "$LASTFIVEDAYSFORECASTEPOCH" ] ; then
									echo  'LASTFIVEDAYFORECASTEPOCH was not empty.'
								fi
								echo "TODAYEPOCH: '$TODAYEPOCH'"
								if [ $LASTFIVEDAYSFORECASTEPOCH -lt $TODAYEPOCH ] ; then
									echo 'LASTFIVEDAYSFORECASTEPOCH was less than TODAYEPOCH'
								else
									echo 'LASTFIVEDAYSFORECASTEPOCH was more than TODAYEPOCH'
								fi
							fi
							;;
						2)	# let's try unrise and sunset
							if [ -z "$LASTSUNRISESUNSETEPOCH" ] || [ $LASTSUNRISESUNSETEPOCH -lt $TODAYEPOCH ]; then
									LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$SUNRISESUNSETMSG: $(date -d "$SUNRISE" +%R)/$(date -d "$SUNSET" +%R)\n$ONEBOT $ONENOISE2 $ONEBOT"
									sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastsunrisesunsettweet")'
							else
								echo 'Unable to use last sunrise/sunset today.'
								echo "LASTSUNRISESUNSETEPOCH: '$LASTSUNRISESUNSETEPOCH'"
								if [ -n "$LASTSUNRISESUNSETEPOCH" ] ; then
									echo  'LASTSUNRISESUNSETPOCH was not empty.'
								fi
								echo "TODAYEPOCH: '$TODAYEPOCH'"
								if [ $LASTSUNRISESUNSETEPOCH -lt $TODAYEPOCH ] ; then
									echo 'LASTSUNRISESUNSETEPOCH was less than TODAYEPOCH'
								else
									echo 'LASTSUNRISESUNSETEPOCH was less than TODAYEPOCH'
								fi

							fi
							;;
						3)	# let's try local news
							NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
							echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (local news list scraper)"
							sleep $NEWSSLEEP
							LISTNAME="https://twitter.com/${BOTNAME/@}/lists/news-l"
							EXTERNALLOCALNEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME")
							if [ -n "$EXTERNALLOCALNEWS" ] ; then
								echo "Tweeting latest external local news as lifesign."
								LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$EXTERNALLOCALNEWS"
							else
								echo "External local news list came up empty."
							fi
							;;
						4)	# let's try competitor news
							NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
							echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (competitor news list scraper)"
							sleep $NEWSSLEEP
							LISTNAME="https://twitter.com/${BOTNAME/@}/lists/competition"
							COMPETITORNEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME" "$CITYGREP")
							if [ -n "$COMPETITORNEWS" ] ; then
								echo "Tweeting latest competitor news as lifesign."
								LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$COMPETITORNEWS"
							else
								echo "Competitor news list came up empty."
							fi
							;;
						5)	# let's try nation-wide news
							NEWSSLEEP="$[ ( $RANDOM % 5 )  + 1 ]s"
							echo "Sleeping for $NEWSSLEEP to avoid bot detection on Twitter (national news list scraper)"
							sleep $NEWSSLEEP
							LISTNAME="https://twitter.com/${BOTNAME/@}/lists/news-n"
							NATIONWIDENEWS=$(get_external_news_infos "$USERAGENT" "$LISTNAME" "$CITYGREP")
							if [ -n "$NATIONWIDENEWS" ] ; then
								echo "Tweeting last external national news as lifesign."
								LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$NATIONWIDENEWS"
							else
								echo "National news list came up empty."
							fi
							;;
						6)	# let's try local events
							# doesn't really make sense past 20:00, unless Friday (5) or Saturday (6) (Sunday would be 0)
							# if we wanted to get really fancy, we could add a "is the next day a public holiday" detection
							if ([ $(date +%H) -lt 20 ] || [ $(date +%w) -gt 4 ]) && \
								([ -z "$LASTEVENTSEPOCH" ] || [ $LASTEVENTSEPOCH -lt $THREEHOURSAGOEPOCH ] ); then
								EVENTSUGGESTION=$(get_external_event_suggestion)
								if [ -n "$EVENTSUGGESTION" ] ; then
									echo "Tweeting event suggestion as lifesign."
									LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$EVENTSUGGESTION"
									sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lasteventstweet")'
								else
									echo "Event suggestion list came up empty."
								fi
							else
								echo "Too late in the day to tweet event suggestions or last event suggestion less than 3h ago."
								echo "Current hour: '$(date +%H)'"
								if [ $(date +%H) -lt 20 ] ; then
									echo "Current hour was less than 20"
								else
									echo "Current hour was greater than 20"
								fi
								if [ -z "$LASTEVENTSEPOCH" ]; then
									echo "LASTEVENTSEPOCH was empty."
								else
							 		echo "LASTEVENTSEPOCH was: '$LASTEVENTSEPOCH'"
								fi
								echo "THREEHOURSAGOEPOCH: '$THREEHOURSAGOEPOCH'"
								if	[ $LASTEVENTSEPOCH -lt $THREEHOURSAGOEPOCH ] ; then
									echo 'LASTEVENTSEPOCH was less than TODAYEPOCH'
								else 
									echo 'LASTEVENTSEPOCH was more than TODAYEPOCH'
								fi

							fi
							;;
						*)	# catch-all, just do nothing here
							# either we'll hit a working entry with the next iteration,
							# or we'll end up with the default chatter message
							: # NOP
							;;
					esac
					LIFESIGNCOUNTER=$((LIFESIGNCOUNTER+1))
				done

				# with a 50% chance, let's show the current weather conditions
				if [ -z "$LIFESIGN" ] && [ $((RANDOM%2)) -gt 0 ] ; then
					echo -e "Tweeting current weather conditions as lifesign."
					LIFESIGN="$ONEBOT $ONENOISE1 $ONEBOT\n$CURRENTWEATHERMSG $(date +%X): $CW\n$ONEBOT $ONENOISE2 $ONEBOT"
				fi

				# no luck, then use the default chatter message
				[ ${#LIFESIGN} -eq $DEFAULTLIFESIGNLENGTH ] && LIFESIGN+=" $(date +"%x %X")"
				echo -e "Lifesign message is: '$LIFESIGN'"

				eval "$TWITTER -status=\"$LIFESIGN\""
				sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastlifesigntweet")'

			else
				echo "Last Tweet was less than 1 h ago (Tweet: '$(date -d "@$LTT" +%X)' | Now: '$(date -d "$NOW" +%X)').  No action needed."
			fi
		fi
	fi
}

function tweet_and_update() {

	local SINGLEURL=$1
	local USERAGENT=$2
	local BACKOFF=$3
	local PRIMETABLE=$4
	local TWEETEDLINK=0

	local SCRAPEDPAGE=$(scrape_swp_page "$SINGLEURL" "$USERAGENT")

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
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted','reason') VALUES ("'$SINGLEURL'","skip","videoonly")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page contains '<meta property="og:type" content="image">' - this is an image-gallery-only page
		elif echo -e "$SCRAPEDPAGE" | grep -q '<meta property="og:type" content="image">' ; then
			echo "Skipping '$SINGLEURL' - image-gallery-only page detected."
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted','reason') VALUES ("'$SINGLEURL'","skip","galleryonly")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page contains NEITHER '<div class="carousel' nor '<div class="image">' nor 'class="btn btn-primary more"' - this is probably a ticker-only page
		elif ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="carousel' && \
		     ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="image">' && \
		     ! echo -e "$SCRAPEDPAGE" | grep -q 'class="btn btn-primary more"' && \
		     ! echo -e "$SCRAPEDPAGE" | grep -q '<div class="inline-element-image-gallerie' && \
		     ! echo -e "$SCRAPEDPAGE" | grep -q '<figcaption' ; then
			echo "Skipping '$SINGLEURL' - no images at all detected in page, probably a ticker message."
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted','reason') VALUES ("'$SINGLEURL'","skip","tickeronly")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		# Page timestamps are all older than 24h
		elif [ $(echo -e "$PUBTIME"| sort -un | tail -n 1) -lt $(date -d '-48 hours' +%s) ]; then
			echo "Skipping '$SINGLEURL' - all timestamps are older than 48h.  Slow news day, eh?"
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage ('url','already_tweeted','reason') VALUES ("'$SINGLEURL'","skip","oldnews")'
			sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastskippedtweet")'
		fi
	fi

	# we need this seemingly identical if block because already_tweeted might get set (to "skip") in the block above, so we should only work on what is left after those checks above
	if [ -n "$(sqlite3 $DBFILE 'SELECT url FROM swphomepage WHERE url = "'$SINGLEURL'" AND already_tweeted = "false"')" ]; then
		# Add SWPPlus Hashtag when required
		if echo -e "$SCRAPEDPAGE" | grep -q '<meta property="lp:paywall" content="1"/>' || echo -e "$SCRAPEDPAGE" | grep -q 'data-freemium="plus"' ; then
			ADORPLUS="#SWPPlus "
			# Add SWPPlus Hashtag when required (new, beta detection)
		elif echo -e "$SCRAPEDPAGE" | grep -q '<svg class="icon p-1 paywall">' ; then
			ADORPLUS="#SWPPlus_beta1 "
			# Add SWPPlus Hashtag when required (new, beta detection)
		elif echo -e "$SCRAPEDPAGE" | grep -q "<use xlink:href='#freemium-swpo'></use>" ; then
			ADORPLUS="#SWPPlus_beta2 "
		# Add SWPAnzeige Hashtag when required
		elif echo -e "$SCRAPEDPAGE" | grep -A2 '<span class="preface d-block font-set-2 txt-color-red">' | grep -q 'ANZEIGE' || echo -e "$SCRAPEDPAGE" | grep -A2 '<span class="preface d-block font-set-2 txt-color-primary">' | grep -q 'ANZEIGE' ; then
			ADORPLUS="#SWPAnzeige "
		else
			ADORPLUS=""
		fi

		# TODO IMPORTANT TITLE needs to be sanitized as well - open to suggestions on how to improve the whitelisting here ...
		# still needs support for accents on letters and similar foo
		# never (unless you want hell to break loose) allow \"'$
		# allowing € leads to allowing UTF-8 in general, it seems? At least tr doesn't see a difference between € and –, which is dumb
		# a "." preceded and followed by at least two non-whitespace characters needs a whitespace inserted right after it, or else twitter might try to turn it into an URL
		TITLE=$(echo "$SCRAPEDPAGE" | grep -A10 title | tr '\n' ' ' | tr -s ' ' | sed -e 's/^.*<title>\([^|]*\)\w*|.*$/\1/' -e 's/–/-/' -e 's/&quot;\(.*\)&quot;/„\1“/g' -e 's/&amp;/\&/g' -e 's#[^a-zäöüA-ZÄÖÜ0-9ß%€„“ _/.,!?&():=-]# #g' -e 's/\(\S\S\)\.\(\S\S\)/\1. \2/g')
		if [ -n "$TITLE" ] ; then
			TITLE="$(echo "$TITLE " | tr -s ' ')" # make sure there is exactly one trailing blank if $TITLE wasn't empty
		fi

		if ! [ "$PRIMETABLE" = "yes" ]; then

			# IMPORTANT: Update times should be randomized within a 120-180 second interval (to work around twitter's bot/abuse detection and API rate limiting)
			RANDDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"

			TITLE="${ADORPLUS}${PREFACE}${TITLE}"
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

			if [ $BACKOFF -lt 1 ]; then
				if [ $BACKOFF -lt 0 ]; then
					echo "We're in postponed tweet checking mode, so let's check if the tweet '$TITLE' has shown up since."
					RANDCHECKDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
					echo -n "Sleeping for $RANDCHECKDELAY to avoid false alerts when checking for tweet visibility ..."
					sleep $RANDCHECKDELAY
					LASTTWEET=$(determine_last_tweet "$USERAGENT" "postponed")
					if already_tweeted "$LASTTWEET" "$TITLE" "$SINGLEURL" ; then
						echo -e " - Already tweeted."
						TWEETEDLINK=1
					fi
				fi
				if ! [ $TWEETEDLINK -eq 1 ] ; then
					# debug: Sometimes we see tweets containing raw html code, merely stripped off <> characters.  Trying to find out why ...
					if echo -e "$MESSAGE" | grep -q 'doctype' ; then
						echo -e "$SCRAPEDPAGE" >$TEMPDIR/scrapedpage.doctype.error
					fi
					echo "About to tweet (in $RANDDELAY): '$MESSAGE' ($((${#TITLE}+24)) characters in total - link and preceding blank count as 24 chars)"
					sleep $RANDDELAY
					TWEETID=""
					TRYAGAIN=0
					# try tweeting twice - if the first attempt returns no tweet ID, but also doesn't complain about tweeting too fast
					while [ -z "$TWEETID" ] && [ $TRYAGAIN -lt 2 ]; do
						TWEETID=$(echo "$MESSAGE" | eval "$TWITTER")
						if [ "$TWEETID" = "ETOOFAST" ]; then
							RANDRETRYDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
							sleep $RANDRETRYDELAY
						fi
						TRYAGAIN=$((TRYAGAIN+1))
					done
					RANDCHECKDELAY="$[ ( $RANDOM % 61 )  + 120 ]s"
					echo -n "Sleeping for $RANDCHECKDELAY to avoid false alerts when checking for tweet visibility ..."
					sleep $RANDCHECKDELAY

					if [ "$TWEETID" = "ETOOFAST" ]; then
						# TWEETING TOO FAST!
						echo -e "\nError tweeting '$MESSAGE'. Tweeting too fast! Storing in table and marking as not yet tweeted."
						echo -e "--------------" >> swpscraper.error
						echo -e "$TITLE" >>swpscraper.error
						echo -e "--------------" >> swpscraper.error
						BACKOFF=1
					elif [ -z "$TWEETID" ]; then
						# if we didn't receive a tweet ID as a reply, we need to perform a webscrape to check if our tweet went out
						LASTTWEET=$(determine_last_tweet "$USERAGENT")
						if already_tweeted "$LASTTWEET" "$TITLE" "$SINGLEURL" ; then
							echo -e " - Tweeted."
							TWEETEDLINK=1
						else
							# unable to spot my own tweet!
							echo -e "\nError tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted."
							echo -e "--------------" >> swpscraper.error
							echo -e "$TITLE" >>swpscraper.error
							echo -e "--------------" >> swpscraper.error
							BACKOFF=1
						fi
					else
						# with a tweet ID, we go straight for a quick check
						SCRAPEDPAGE=$(scrape_twitter_page "https://nitter.net/${BOTNAME/@}/status/${TWEETID}" "$USERAGENT")
						if echo -e "$SCRAPEDPAGE" | grep -q ">Tweet not found<"; then
							# unable to spot my own tweet!
							echo -e "\nError tweeting '$MESSAGE'. Storing in table and marking as not yet tweeted."
							echo -e "--------------" >> swpscraper.error
							echo -e "$TITLE" >>swpscraper.error
							echo -e "--------------" >> swpscraper.error
							BACKOFF=1
						else
							# This is cheating, as already_tweeted checks if the content of the third parameter is contained in the first
							already_tweeted "$SINGLEURL" "$TITLE" "$SINGLEURL"
							echo -e " - Tweeted."
							TWEETEDLINK=1
						fi
					fi
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
		REASON="$(sqlite3 $DBFILE 'SELECT reason FROM swphomepage WHERE url="'$SINGLEURL'"')"
		sleep 1 # make sure timestamps are always at least 1s apart
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO swphomepage (url,already_tweeted,reason) VALUES ("'$SINGLEURL'","'$TWEETSTATE'","'$REASON'")'
		sqlite3 $DBFILE 'INSERT OR REPLACE INTO state ('status') VALUES ("lastupdatedtweet")'
	fi

	echo "Done processing '$SINGLEURL'"

	if [ $BACKOFF -eq 1 ]; then
		echo "Setting BACKOFF."
		return 1
	else
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

# make sure table swphomepage has a "reason" column
if ! sqlite3 $DBFILE 'PRAGMA table_info(swphomepage)' | grep -q '|reason|'; then
	sqlite3 $DBFILE 'ALTER TABLE swphomepage ADD COLUMN reason'
fi

# this is to purge entries older than 8 days (to keep the database small)
sqlite3 $DBFILE 'delete from swphomepage where timestamp < datetime("now","-8 days")'
sqlite3 $DBFILE 'delete from externalurls where timestamp < datetime("now","-8 days")'

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

# to look at the database content, run:
# sqlite3 $DBFILE 'SELECT datetime(timestamp,"localtime"),url FROM swphomepage ORDER BY timestamp'

# check for shadowban
# nitter.net doesn't work here ... yet? (it always shows search results)
# if [ $(timeout 60 wget -q --post-data="" -O - --referer 'https://nitter.net/'"${BOTNAME/@}"'/search?f=tweets&q='"${BOTNAME/@}"'&since=&until=&near=&src=typd' | grep -i '/'${BOTNAME/@}'/' -c) -lt 1 ] ; then
# this doesn't work any more as twitter is blocking anonymous (non-logged-in) searches and also requires javascript, even on mobile
# if [ $(timeout 60 wget -q --post-data="" -O - --referer 'https://twitter.com/search?f=tweets&vertical=default&q=from%3A%40'"${BOTNAME/@}"'&src=typd' 'https://mobile.twitter.com/i/nojs_router?path=%2Fsearch%3Ff%3Dtweets%26vertical%3Ddefault%26q%3Dfrom%253A%2540'"${BOTNAME/@}"'%26src%3Dtypd' | grep -i '/'${BOTNAME/@}'/' -c) -lt 1 ] ; then
# 	echo "No search results - have we been shadowbanned?"
# fi


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
		# NOTE: This is now broken and will also ignore some of the links on the main page.  Recommendation is to use fullpage and white-/blacklists instead.
		URLLIST+="$(LANG=C timeout 60 lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly "$SINGLEBASEURL" 2>/dev/null | sed '0,/Hidden links:$/d' | awk ' $2 ~ /^http.*html$/ { print $2 }' )\n"
	elif [ "$LINKTYPE" = "tickeronly" ]; then
		# Alternatively, the following call will *only* tweet the "ticker" at the bottom of the front page
		# (however, it doesn't work for subpages like 'https://www.swp.de/suedwesten/staedte/ulm', so only use it for the front page)
		URLLIST+="$(timeout 60 lynx -useragent "$USERAGENT" -dump -hiddenlinks=ignore "$SINGLEBASEURL" | awk ' $2 ~ /^http.*html$/ { print $2 }')\n"
	else
		# Default: this will scrape all news from the page, including the "ticker" at the bottom of the front page, if pointed at the front page
		URLLIST+="$(timeout 60 lynx -useragent "$USERAGENT" -dump -hiddenlinks=listonly "$SINGLEBASEURL" 2>/dev/null | awk ' $2 ~ /^http.*html$/ { print $2 }')\n"
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

BACKOFF=0
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
	# $(echo -e '\U0001f916')"*krrrrk* Sand im Twittergetriebe *krrrrk*"$(echo -e '\U0001f916')
	exit 1
else
#	heartbeat "$USERAGENT" "$PRIMETABLE"
	echo "Done."
	exit 0
fi

#### END MAIN PROGRAM ####
