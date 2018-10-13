require 'helper'
require 'net/http'
require 'fluent/test/driver/input'

class HerokuSyslogHttpInputTest < Test::Unit::TestCase
  class << self
    def startup
      socket_manager_path = ServerEngine::SocketManager::Server.generate_path
      @server = ServerEngine::SocketManager::Server.open(socket_manager_path)
      ENV['SERVERENGINE_SOCKETMANAGER_PATH'] = socket_manager_path.to_s
    end

    def shutdown
      @server.close
    end
  end

  def setup
    Fluent::Test.setup
  end

  PORT = unused_port
  CONFIG = %[
    port #{PORT}
    bind 127.0.0.1
    body_size_limit 10m
    keepalive_timeout 5
    tag heroku
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HerokuSyslogHttpInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal PORT, d.instance.port
    assert_equal '127.0.0.1', d.instance.bind
    assert_equal 10*1024*1024, d.instance.body_size_limit
    assert_equal 5, d.instance.keepalive_timeout
    assert_equal 'heroku', d.instance.tag
  end

  def test_configuring_drain_ids
    d = create_driver(CONFIG + %[drain_ids ["abc"]])
    assert_equal d.instance.drain_ids, ["abc"]
  end

  def test_time_format
    d = create_driver
    time_parser = Fluent::TimeParser.new

    tests = [
      "59 <13>1 2014-01-29T06:25:52.589365+00:00 host app web.1 - foo",
      "59 <13>1 2014-01-30T07:35:00.123456+09:00 host app web.1 - bar"
    ]

    d.run(expect_records: 2) do
      res = post(tests)
      assert_equal "200", res.code
    end

    assert_equal d.events[0], ['heroku', time_parser.parse('2014-01-29T06:25:52.589365+00:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident"=>"app",
      "pid"=>"web.1",
      "message"=>"foo",
      "facility"=>"user",
      "priority"=>"notice"
    }]

    assert_equal d.events[1], ['heroku', time_parser.parse('2014-01-30T07:35:00.123456+09:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident"=>"app",
      "pid"=>"web.1",
      "message"=> "bar",
      "facility" => "user",
      "priority" => "notice"
    }]
  end

  def test_msg_size
    d = create_driver
    time_parser = Fluent::TimeParser.new

    tests = [
      '156 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 100,
      '1080 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 1024
    ]

    d.run(expect_records: 2) do
      res = post(tests)
      assert_equal "200", res.code
    end

    assert_equal d.events[0], ['heroku', time_parser.parse('2014-01-01T01:23:45.123456+00:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident" => "app",
      "pid" => "web.1",
      "message" => "x" * 100,
      "facility" => "user",
      "priority" => "notice"
    }]

    assert_equal d.events[1], ['heroku', time_parser.parse('2014-01-01T01:23:45.123456+00:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident" => "app",
      "pid" => "web.1",
      "message" => "x" * 1024,
      "facility" => "user",
      "priority" => "notice"
    }]
  end

  def test_accept_matched_drain_id_multiple
    d = create_driver(CONFIG + "\ndrain_ids [\"abc\", \"d.fc6b856b-3332-4546-93de-7d0ee272c3bd\"]")
    time_parser = Fluent::TimeParser.new

    tests = [
      '156 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 100,
      '1080 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - ' + 'x' * 1024
    ]

    d.run(expect_records: 2) do
      res = post(tests)
      assert_equal "200", res.code
    end

    assert_equal d.events[0], ['heroku', time_parser.parse('2014-01-01T01:23:45.123456+00:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident" => "app",
      "pid" => "web.1",
      "message" => "x" * 100,
      "facility" => "user",
      "priority" => "notice"
    }]

    assert_equal d.events[1], ['heroku', time_parser.parse('2014-01-01T01:23:45.123456+00:00'), {
      "drain_id" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "ident" => "app",
      "pid" => "web.1",
      "message" => "x" * 1024,
      "facility" => "user",
      "priority" => "notice"
    }]
  end

  def test_ignore_unmatched_drain_id
    d = create_driver(CONFIG + "\ndrain_ids [\"abc\"]")

    tests = [
      '58 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - x',
      '58 <13>1 2014-01-01T01:23:45.123456+00:00 host app web.1 - y'
    ]

    d.run(expect_records: 0) do
      res = post(tests)
      assert_equal "200", res.code
    end

    assert_equal(0, d.events.length)
  end

  def post(messages)
    # https://github.com/heroku/logplex/blob/master/doc/README.http_drains.md
    http = Net::HTTP.new("127.0.0.1", PORT)
    req = Net::HTTP::Post.new('/heroku', {
      "Content-Type" => "application/logplex-1",
      "Logplex-Msg-Count" => messages.length.to_s,
      "Logplex-Frame-Id" => "09C557EAFCFB6CF2740EE62F62971098",
      "Logplex-Drain-Token" => "d.fc6b856b-3332-4546-93de-7d0ee272c3bd",
      "User-Agent" => "Logplex/v49"
    })
    req.body = messages.join("\n")
    http.request(req)
  end

end
