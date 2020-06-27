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

def change_event(event)
  type = event["type"].sub("Event", "")
  return event if type != "Create"

  payload = event["payload"]
  # change first commit to push
  if  !payload["ref"] 
    event["type"] = "Push"
    return event
  end
  # change to tag event
  if payload["ref_type"] == "tag"
    event["type"] = "Tag"
    return event
  end

  event
end

JSON.parse(res.body).each do |event|
  # event time
  time = Time.parse(event["created_at"]).localtime
  if time.year != target.year || time.month != target.month || time.day != target.day
    next
  end

  event = change_event(event)
  # event type
  type = event["type"].sub("Event", "")
  # count event
  events[type] = (events[type] || 0) + 1

  puts type + " " + event["repo"]["name"]
end

if events.length == 0
  puts target
  puts "no activity"
  return
end

puts "------------------"

text = "GitHub Activity - #{target.strftime("%Y/%m/%d")} \n\n"
events.keys.sort.each do |k|
  text << "#{k} : #{events[k]}\n"
end

puts text

tokens = open(File.join(File.dirname(__FILE__), "secret.txt"), &:read).split("\n")

@client = Twitter::REST::Client.new do |config|
  config.consumer_key        = tokens[0]
  config.consumer_secret     = tokens[1]
  config.access_token        = tokens[2]
  config.access_token_secret = tokens[3]
end

@client.update(text)

