# swpscraper
Since swp.de stopped tweeting their headlines at @SWPde, it's time for a web2tweet-gateway

Needs: curl echo tr bash sleep sqlite3 wget grep sed awk test lynx uniq oysttyer ansiweather

Note: Oysttyer can be git cloned from https://github.com/oysttyer/oysttyer.git

TODO: try to handle everything with curl, or at least replace wget with curl; place swpscraper.sh in /usr/local/bin/ or similar, add cron job (be sure to check if script is already running, you don't want multiple instances), check why URLLIST still isn't unique, 


Ideas for the future: split script in half - one for scraping and updating the DB, one for selecting URLs from the DB and tweeting them; use xmlstarlet for scraping instead of lynx -dump - might allow better selection of what is a headline link and what not. Also, actual articles (as opposed to galleries and videos) have a json block with datePublished, dateModified, and image (this is the preview image Twitter grabs).  If the image tag contains "opengraphlogo.png", it's an article without an actual image, so it can be skipped. Parsing this json block might make it easier to tell which articles should be tweeted and which not. Another criteria could be if the page text contains the strings "Symbolbild" or "Symbolfoto".

Questions, suggestions, etc.: https://twitter.com/farbenstau

Update 1: Looks like somebody already decided to put this code to good use and is operating a Twitter bot with it.  Follow https://twitter.com/SWPde_bot while it's still alive (my guess is that either Twitter or SWP will enforce a shutdown soon, so let's hope for the Streisand effect to kick in).

Update 2: Looks like @SWPde has reactivated and unlocked their Twitter account, and they are tweeting again.  I'm curious if they will continue ...

Update 3: Sadly, the @SWPde account has become inactive again. :'(  But at least it's still around and unprotected. :)
