# swpscraper
Since swp.de stopped tweeting their headlines at @SWPde, it's time for a web2tweet-gateway

Needs: curl echo tr bash sleep sqlite3 wget grep sed awk test lynx uniq ansiweather python3

Note: swpscraper also needs a tweeting backend. This used to be Oysttyer, but has now been switched to tweepy. Instructions on how to install tweepy can be found here: https://github.com/tweepy/tweepy

You will also need a separate Python script to send out the tweets. Do NOT name this tweepy.py, but rather tweet-with-tweepy.py or something like that.

This file (actual code below) needs to be chmodded 755 and placed in `../tweepy/` - if you want to place it anywhere else, or use a different name, you need to set the TWITTER variable accordingly.
```
#!/usr/bin/python3
import tweepy

# You need to insert your Twitter API keys here!
consumer_key = ""
consumer_secret = ""
access_token = ""
access_token_secret = ""

client = tweepy.Client(
    consumer_key=consumer_key, consumer_secret=consumer_secret,
    access_token=access_token, access_token_secret=access_token_secret
)

response = client.create_tweet(
    text=input()
)
print(f"{response.data['id']}")
```

TODO: try to handle everything with curl, or at least replace wget with curl; place swpscraper.sh in /usr/local/bin/ or similar, add cron job (be sure to check if script is already running, you don't want multiple instances)

Ideas for the future: split script in half - one for scraping and updating the DB, one for selecting URLs from the DB and tweeting them; use xmlstarlet for scraping instead of lynx -dump - might allow better selection of what is a headline link and what not.

Questions, suggestions, etc.: https://twitter.com/farbenstau

Update 1: Looks like somebody already decided to put this code to good use and is operating a Twitter bot with it.  Follow https://twitter.com/SWPde_bot while it's still alive (my guess is that either Twitter or SWP will enforce a shutdown soon, so let's hope for the Streisand effect to kick in).

Update 2: Looks like @SWPde has reactivated and unlocked their Twitter account, and they are tweeting again.  I'm curious if they will continue ...

Update 3: Sadly, the @SWPde account has become inactive again. :'(  But at least it's still around and unprotected. :)
