#!ruby

require_relative './tweet_github_activity'

@user = "basyura"
@date = Time.now - 24 * 60 * 60 * 0
TweetAcivity.new.tweet(@user, @date)

