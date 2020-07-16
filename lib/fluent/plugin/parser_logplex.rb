module Fluent
  module Plugin
    class Logplex < Parser
      # Parses syslog-formatted messages[1], framed using syslog TCP protocol octet counting framing method[2]
      # [1] https://tools.ietf.org/html/rfc5424#section-6
      # [2] https://tools.ietf.org/html/rfc6587#section-3.4.1
      HTTPS_REGEXP = /^([0-9]+)\s+\<(?<pri>[0-9]+)\>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?<pid>[a-zA-Z0-9\.]+)? *- *(?<message>.*)$/

      FACILITY_MAP = Fluent::Plugin::SyslogInput::FACILITY_MAP
      # Constant was renamed in 1.7.3.
      PRIORITY_MAP = if Gem::Version.new(Fluent::VERSION) >= Gem::Version.new('1.7.3')
                       Fluent::Plugin::SyslogInput::SEVERITY_MAP
                     else
                       Fluent::Plugin::SyslogInput::PRIORITY_MAP
                     end

      # https://tools.ietf.org/html/rfc5424#section-6.2.1 describes FACILITY
      # as multiplied by 8 (3 bits), so this is used to shift the values to
      # calculate FACILITY from PRIVAL.
      FACILITY_SHIFT = 3
      # Priority is the remainder after removing FACILITY from PRI, so it is
      # calculated by bitwise AND to remove the FACILITY value.
      PRIORITY_MASK = 0b111

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

              # Process 'pri' field
              next unless name == 'pri'
              pri = m[name].to_i
              record['pri'] = pri
              # Split PRIVAL into Facility and Severity
              record['facility'] = FACILITY_MAP[pri >> FACILITY_SHIFT]
              record['priority'] = PRIORITY_MAP[pri & PRIORITY_MASK]
            end
          end

        records.each { |record| record.delete('pri') }
        yield nil, records
      end
    end
  end
end
