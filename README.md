# swpscraper
Since swp.de stopped tweeting their headlines at @SWPde, it's time for a web2tweet-gateway

Needs: echo tr bash twidge sleep sqlite3 wget grep sed awk test lynx uniq

TODO: store DB in a suitable directory, add path to DB file for every sqlite3 call, place swpscraper.sh in /usr/local/bin/ or similar, add cron job (be sure to check if script is already running, you don't want multiple instances)

Idea for the future: split script in half; one for scraping and updating the DB, one for selecting URLs from the DB and tweeting them
