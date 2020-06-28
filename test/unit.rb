require 'test/unit'
require 'test/unit/rr'
require 'json'
require '../tweet_github_activity'

class UniteTest < Test::Unit::TestCase
  #
  #
  def test_today_fetch_github
    client = TweetAcivity.new
    events = client.__send__("fetch", "basyura", Time.now - 24 * 60 * 60 * 3)
  end
  #
  #
  def test_fetch
    client = TweetAcivity.new
    stub(client).fetch_events("basyura") { read_json("events.json") }

    assert = Proc.new do |month, day, proc|
      events = client.__send__("fetch", "basyura", Time.local(2020, month, day))
      puts "#{month}/#{day}----------------"
      puts events
      proc.call(events)
    end
    
    # 6.28
    assert.call(6, 28, proc {|events|
      assert_equal events.length, 1
      assert_equal events["Watch"], 1
    })
    # 6.27
    assert.call(6, 27, proc {|events|
      assert_equal events.length, 1
      assert_equal events["Push"], 2
    })
    # 6.26
    assert.call(6, 26, proc {|events|
      assert_equal events.length, 0
    })
    # 6.25
    assert.call(6, 25, proc {|events|
      assert_equal events.length, 3
      assert_equal events["Push"], 5
      assert_equal events["Tag"], 1
      assert_equal events["Create"], 1
    })
    # 6.24
    assert.call(6, 24, proc {|events|
      assert_equal events.length, 0
    })
    # 6.23
    assert.call(6, 23, proc {|events|
      assert_equal events.length, 0
    })
    # 6.22
    assert.call(6, 22, proc {|events|
      assert_equal events.length, 2
      assert_equal events["Push"], 2
      assert_equal events["IssueComment"], 1
    })
    # 6.21
    assert.call(6, 21, proc {|events|
      assert_equal events.length, 3
      assert_equal events["Push"], 3
      assert_equal events["Create"], 1
      assert_equal events["Watch"], 1
    })
    # 6.20
    assert.call(6, 20, proc {|events|
      assert_equal events.length, 6
      assert_equal events["PullRequest"], 1
      assert_equal events["Create"], 2
      assert_equal events["Delete"], 1
      assert_equal events["Push"], 4
      assert_equal events["Fork"], 1
      assert_equal events["IssueComment"], 1
    })
  end
  #
  #
  private def read_json(name)
    text = open(File.join(File.dirname(__FILE__), "fixtures", name), &:read)
    JSON.parse(text)
  end
end
