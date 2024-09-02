#!/usr/bin/python3
import tweepy
import json
import tempfile
import urllib.request
import os

with open("../tweepy_credentials.json") as cred_file:
      credentials = json.load(cred_file)

try:
    # V1 Twitter API Auth for media 
    auth = tweepy.OAuthHandler(credentials["consumer_key"], credentials["consumer_secret"])
    auth.set_access_token(credentials["access_token"], credentials["access_token_secret"])
    api = tweepy.API(auth, wait_on_rate_limit=False)
    # V2 Twitter API Auth for text                      
    client = tweepy.Client(
        consumer_key=credentials["consumer_key"], consumer_secret=credentials["consumer_secret"],
        access_token=credentials["access_token"], access_token_secret=credentials["access_token_secret"],
        wait_on_rate_limit=False
        #wait_on_rate_limit=True
    )
    inputstring = input()
    message = inputstring.split(" IMAGEURL:https://")
    if len(message) < 2:
        tweettext=inputstring
        tweetimageurl=""
    else:
        tweettext=message[0]
        tweetimageurl=message[1]

    if tweetimageurl:
      fetchimageurl = "https://"+tweetimageurl
      tf = tempfile.NamedTemporaryFile(delete=False)
      # print(tf.name)
      tweetcontent=tweettext.split(" http")
      refererurl="http"+tweetcontent[1]
      # print(refererurl)


      # req = urllib.request.Request(fetchimageurl)
      # req.add_header('Referer', refererurl)
      # # Customize the default User-Agent header value:
      # req.add_header('User-Agent', 'I am a fancy user agent')
      # r = urllib.request.urlopen(req)
      # tf.write(r.read)

      urllib.request.urlretrieve(fetchimageurl, tf.name)

      media_id = api.media_upload(filename = tf.name).media_id_string
      response = client.create_tweet(
          text = tweettext, media_ids = [media_id]
      )
      if response:
          os.remove(tf.name)
      else:
          print(tf.name)

    else:
      response = client.create_tweet(
          text = tweettext
      )
    
except tweepy.errors.TooManyRequests:
    print("ETOOFAST")
    exit(1)
except Exception:
    exit(1)

print(response.data['id'])
