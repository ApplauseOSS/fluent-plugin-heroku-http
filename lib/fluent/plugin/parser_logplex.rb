module Fluent
  module Plugin
    class Logplex < Parser
      HTTPS_REGEXP = /^([0-9]+)\s+\<(?<pri>[0-9]+)\>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?<pid>[a-zA-Z0-9\.]+)? *- *(?<message>.*)$/

      FACILITY_MAP = Fluent::Plugin::SyslogInput::FACILITY_MAP
      PRIORITY_MAP = Fluent::Plugin::SyslogInput::PRIORITY_MAP

      Plugin.register_parser('logplex', self)

      config_set_default :time_key, 'time'

      config_param :with_priority, :bool, default: true

      def parse(text)
        expression = HTTPS_REGEXP

        records =
          text.split("\n").map do |line|
            m = line.match(expression)

            m.names.each_with_object({}) do |name, record|
              record[name] = m[name]

              next unless name == 'pri'
              pri = m[name].to_i
              record['pri'] = pri
              record['facility'] = FACILITY_MAP[pri >> 3]
              record['priority'] = PRIORITY_MAP[pri & 0b111]
            end
          end

        records.each { |record| record.delete('pri') }
        yield nil, records
      end
    end
  end
end
