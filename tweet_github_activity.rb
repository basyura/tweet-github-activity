#!ruby

require "net/http"
require 'json'
require 'time'
require 'twitter'
require 'rsvg2'
require 'nokogiri'
require 'open-uri'

class TweetAcivity
  #
  #
  def tweet(user, date)

    events = fetch(user, date)
    if events.length == 0
      puts "#{date}\nno activity"
      return
    end

    text = generate_text(user, date, events)
    png_path = generate_imgage(user) 

    puts "----------------------------------"
    puts text
    puts png_path

    post_tweet(text, png_path)
    # `open #{png_path}`
  end
  #
  # for solargraph
  private
  #
  #
  private def fetch(user, date)
    # fetch github.com
    events = {}
    fetch_events(user).each do |event|
      time = Time.parse(event["created_at"]).localtime
      if time.year != date.year || time.month != date.month || time.day != date.day
        next
      end

      event = change_event(event)
      # event type
      type = event["type"].sub("Event", "")
      # count event
      if type == "Push"
        events["Commit"] = (events["Commit"] || 0) + event["payload"]["size"].to_i
      else
        events[type] = (events[type] || 0) + 1
      end
    end

    events
  end
  #
  #
  private def fetch_events(user)

    uri = URI.parse("https://api.github.com/users/#{user}/events")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.get(uri.path, Authorization: "token #{access_token}")
    JSON.parse(res.body)
  end
  #
  #
  private def change_event(event)
    type = event["type"].sub("Event", "")
    return event if type != "Create"

    payload = event["payload"]
    # change first commit to push (CreateEvent -> PushEvent)
    if !payload["ref"] 
      event["type"] = "Push"
      event["payload"]["size"] = 1
      return event
    end
    # change to tag event
    if payload["ref_type"] == "tag"
      event["type"] = "Tag"
      return event
    end

    event
  end
  #
  #
  private def generate_text(user, date, events)
    text = "#{user}'s activity - #{date.strftime("%Y/%m/%d")} \n\n"
    events.keys.sort.each do |k|
      text << "#{k} : #{events[k]}\n"
    end
    text
  end
  #
  #
  private def generate_imgage(user)
    # fetch svg xml
    doc = Nokogiri::HTML(open("https://github.com/#{user}"))
    xml = doc.search('div.js-calendar-graph svg').first.to_s
    # replace style by data-level
    xml = xml.gsub('data-level="0"', 'fill="rgba(27, 31, 35, 0.06)"')
    xml = xml.gsub('data-level="1"', 'fill="rgb(155, 233, 168)"')
    xml = xml.gsub('data-level="2"', 'fill="rgb(64, 196, 99)"')
    xml = xml.gsub('data-level="3"', 'fill="rgb(48, 161, 78)"')
    xml = xml.gsub('data-level="4"', 'fill="rgb(33, 110, 57)"')

    # convert background to white
    xml = xml.sub("<svg ", "<svg style=\"fill: black\" ")
    xml = xml.sub(
      '<svg style="fill: black" width="828" height="128" class="js-calendar-graph-svg">',
      '<svg fill="black" width="828" height="128" class="js-calendar-graph-svg">
         <path d="M0 0 L 828 0 L 828 320 L 0 320" style="fill:#FFFFFF;stroke-width:0" />')

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
  #
  #
  private def post_tweet(text, png_path)
    tokens = open(config_path, &:read).split("\n")
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = tokens[0]
      config.consumer_secret     = tokens[1]
      config.access_token        = tokens[2]
      config.access_token_secret = tokens[3]
    end

    client.update_with_media(text, open(png_path))
  end
  #
  #
  private def access_token
    if !@access_token
      @access_token = ""
      if File.exists?(config_path)
        tokens = open(config_path, &:read).split("\n")
        @access_token = tokens.length >= 5 ? tokens[4] : ""
      end
    end
    @access_token
  end
  #
  #
  private def config_path
    File.join(File.dirname(__FILE__), "secret.txt")
  end
end
