#!ruby

require "net/http"
require 'json'
require 'time'
require 'twitter'

user = "basyura"

uri = URI.parse("https://api.github.com/users/" + user + "/events")
res = Net::HTTP.get_response(uri)

events = {}
target = Time.now - 24 * 60 * 60

JSON.parse(res.body).each do |event|
  # event time
  time = Time.parse(event["created_at"]).localtime
  if time.year != target.year || time.month != target.month || time.day != target.day
    next
  end
  # event type
  type = event["type"].sub("Event", "")
  # count event
  events[type] = (events[type] || 0) + 1
end

text = "GitHub Activity\n"
events.keys.sort.each do |k|
  text << "#{k} : #{events[k]}\n"
end

tokens = open(File.join(File.dirname(__FILE__), "secret.txt"), &:read).split("\n")

@client = Twitter::REST::Client.new do |config|
  config.consumer_key        = tokens[0]
  config.consumer_secret     = tokens[1]
  config.access_token        = tokens[2]
  config.access_token_secret = tokens[3]
end

@client.update(text)

#@client.home_timeline.each do |tweet|
#  puts tweet.user.name + ":" + tweet.user.screen_name
#  puts tweet.text
#end
