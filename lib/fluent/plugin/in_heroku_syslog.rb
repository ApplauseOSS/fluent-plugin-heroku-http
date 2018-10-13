require 'fluent/plugin/in_syslog'
require_relative 'logplex'

module Fluent
  module Plugin
    class HerokuSyslogInput < SyslogInput
      Fluent::Plugin.register_input('heroku_syslog', self)

      config_param :tag, :string
      config_param :drain_ids, :array, default: nil

      config_section :parse do
        config_set_default :@type, 'logplex'
        config_set_default :kind, 'syslog_drain'
      end
    end
  end
end
