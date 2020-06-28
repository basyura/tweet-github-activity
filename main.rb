#!ruby

require './tweet_github_activity'

@user = "basyura"
@date = Time.now - 24 * 60 * 60 * 1
TweetAcivity.new.tweet(@user, @date)

