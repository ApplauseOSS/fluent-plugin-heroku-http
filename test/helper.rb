# frozen_string_literal: true

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fileutils'
require 'fluent/log'
require 'fluent/test'

unless defined?(Test::Unit::AssertionFailedError)
  module Test
    module Unit
      class AssertionFailedError < StandardError
      end
    end
  end
end

def unused_port
  s = TCPServer.open(0)
  port = s.addr[1]
  s.close
  port
end

def ipv6_enabled?
  require 'socket'

  begin
    TCPServer.open('::1', 0)
    true
  rescue StandardError
    false
  end
end

require 'fluent/plugin/in_http_content_negotiation'

module Test
  module Unit
    class TestCase
    end
  end
end
