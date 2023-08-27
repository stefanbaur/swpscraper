#!/usr/bin/python3
import tweepy
import json

with open("../tweepy_credentials.json") as cred_file:
      credentials = json.load(cred_file)

try:
    client = tweepy.Client(
        consumer_key=credentials["consumer_key"], consumer_secret=credentials["consumer_secret"],
        access_token=credentials["access_token"], access_token_secret=credentials["access_token_secret"],
        wait_on_rate_limit=True
    )

    response = client.create_tweet(
        text=input()
    )
except tweepy.errors.TooManyRequests:
    print("ETOOFAST")
    exit(1)
except Exception:
    exit(1)

print(response.data['id'])
