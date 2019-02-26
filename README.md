# swpscraper
Since swp.de stopped tweeting their headlines at @SWPde, it's time for a web2tweet-gateway

Needs: echo tr bash twidge sleep sqlite3 wget grep sed awk test lynx uniq

TODO: store DB in a suitable directory, add path to DB file for every sqlite3 call, place swpscraper.sh in /usr/local/bin/ or similar, add cron job (be sure to check if script is already running, you don't want multiple instances)

Ideas for the future: split script in half - one for scraping and updating the DB, one for selecting URLs from the DB and tweeting them; use xmlstarlet for scraping instead of lynx -dump - might allow better selection of what is a headline link and what not

Questions, suggestions, etc.: https://twitter.com/farbenstau

Update: Looks like somebody already decided to put this code to good use and is operating a Twitter bot with it.  Follow https://twitter.com/SWPde_bot while it's still alive (my guess is that either Twitter or SWP will enforce a shutdown soon, so let's hope for the Streisand effect to kick in).
