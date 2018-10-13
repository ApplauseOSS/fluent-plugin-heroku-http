module Fluent
  module Plugin
  class Logplex < Parser
    SYSLOG_REGEXP = /^([0-9]+)\s+\<(?<pri>[0-9]+)\>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?<pid>[a-zA-Z0-9\.]+)? *(?<message>.*)$/
    SYSLOG_HTTPS_REGEXP = /^([0-9]+)\s+\<(?<pri>[0-9]+)\>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?<pid>[a-zA-Z0-9\.]+)? *- *(?<message>.*)$/

    FACILITY_MAP = Fluent::Plugin::SyslogInput::FACILITY_MAP
    PRIORITY_MAP = Fluent::Plugin::SyslogInput::PRIORITY_MAP

    Plugin.register_parser("logplex", self)

    desc 'Kind of message to be parsed'
    config_param :kind, :enum, list: [:syslog_drain, :syslog_https_drain]

    config_set_default :time_key, 'time'

    config_param :with_priority, :bool, default: true

    def parse(text)
      expression =
        case kind
        when "syslog_drain" then SYSLOG_REGEXP
        when "syslog_https_drain" then SYSLOG_HTTPS_REGEXP
        end

      # TODO: parse depending on the kind?

      records =
        text.split("\n").map do |line|
          m = line.match(expression)

          m.names.reduce({}) do |record, name|
            record[name] = m[name]

            if name == 'pri'
              pri = m[name].to_i
              record['pri'] = pri
              record['facility'] = FACILITY_MAP[pri >> 3]
              record['priority'] = PRIORITY_MAP[pri & 0b111]
            end

            record
          end
        end

      case kind
      when "syslog_drain"
        record = records.first
        time = record.delete('time')

        yield  time, record
      when "syslog_https_drain"
        records.each { |record| record.delete('pri') }

        yield nil, records
      end
    end
  end
  end
end
