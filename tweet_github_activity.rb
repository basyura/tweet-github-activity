#!ruby

require "net/http"
require 'json'
require 'time'
require 'twitter'
require 'rsvg2'
require 'nokogiri'
require 'open-uri'

@user = "basyura"
@date = Time.now - 24 * 60 * 60

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

def generate_imgage(user)
  # fetch svg xml
  doc = Nokogiri::HTML(open("https://github.com/#{user}"))
  xml = doc.search('div.js-yearly-contributions svg').first.to_s

  # write file. (todo: tempfile)
  png_path = File.join(File.dirname(__FILE__), "#{user}.png")
  File.delete(png_path) if File.exist?(png_path)
  File.open(png_path, mode = "w"){|f|
    svg = RSVG::Handle.new_from_data(xml)
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, 828, 128)
    context = Cairo::Context.new(surface)
    context.render_rsvg_handle(svg)
    surface.write_to_png(f)
  }

  png_path
end

uri = URI.parse("https://api.github.com/users/" + @user + "/events")
res = Net::HTTP.get_response(uri)
events = {}

JSON.parse(res.body).each do |event|
  # event time
  time = Time.parse(event["created_at"]).localtime
  if time.year != @date.year || time.month != @date.month || time.day != @date.day
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
  puts @date
  puts "no activity"
  return
end

puts "------------------"

text = "#{@user}'s activity - #{@date.strftime("%Y/%m/%d")} \n\n"
events.keys.sort.each do |k|
  text << "#{k} : #{events[k]}\n"
end

png_path = generate_imgage(@user) 

puts text
puts png_path

tokens = open(File.join(File.dirname(__FILE__), "secret.txt"), &:read).split("\n")

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = tokens[0]
  config.consumer_secret     = tokens[1]
  config.access_token        = tokens[2]
  config.access_token_secret = tokens[3]
end

client.update_with_media(text, open(png_path))

