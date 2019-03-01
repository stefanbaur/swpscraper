# swpscraper
Since swp.de stopped tweeting their headlines at @SWPde, it's time for a web2tweet-gateway

Needs: curl echo tr bash sleep sqlite3 wget grep sed awk test lynx uniq oysttyer

Note: Oysttyer can be git cloned from https://github.com/oysttyer/oysttyer.git

TODO: try to handle everything with curl, or at least replace wget with curl; place swpscraper.sh in /usr/local/bin/ or similar, add cron job (be sure to check if script is already running, you don't want multiple instances)

Ideas for the future: split script in half - one for scraping and updating the DB, one for selecting URLs from the DB and tweeting them; use xmlstarlet for scraping instead of lynx -dump - might allow better selection of what is a headline link and what not.  Pages also have meta property="article:published_time" content="TIMESTAMP", meta property="article:modified_time" content="TIMESTAMP" meta property="article:expiration_time" content="TIMESTAMP" fields that could be parsed.  These timestamps might come in handy.

Questions, suggestions, etc.: https://twitter.com/farbenstau

Update 1: Looks like somebody already decided to put this code to good use and is operating a Twitter bot with it.  Follow https://twitter.com/SWPde_bot while it's still alive (my guess is that either Twitter or SWP will enforce a shutdown soon, so let's hope for the Streisand effect to kick in).

Update 2: Looks like @SWPde has reactivated and unlocked their Twitter account, and they are tweeting again.  I'm curious if they will continue ...
