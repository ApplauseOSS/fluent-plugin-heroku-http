# frozen_string_literal: true

require 'fluent/version'
require 'fluent/plugin/in_syslog'

module Fluent
  module Plugin
    class Logplex < Parser
      # Parses syslog-formatted messages[1], framed using syslog TCP protocol octet counting framing method[2]
      # [1] https://tools.ietf.org/html/rfc5424#section-6
      # [2] https://tools.ietf.org/html/rfc6587#section-3.4.1
      HTTPS_REGEXP = %r{^([0-9]+)\s+<(?<pri>[0-9]+)>[0-9]* (?<time>[^ ]*) (?<drain_id>[^ ]*) (?<ident>[a-zA-Z0-9_/.\-]*) (?<pid>[a-zA-Z0-9.]+)? *- *(?<message>.*)$}
      DYNATRACE_FIELDS_REGEXP = /(?=.*dt.entity.host: (?<dt.entity.host>[^ ^,]+))(?=.*dt.entity.process_group_instance: (?<dt.entity.process_group_instance>[^ ^,]+))(?=.*dt.trace_id: (?<trace_id>[^ ^,]+))(?=.*dt.span_id: (?<span_id>[^ ^,]+))/
      DYNATRACE_META_SECTION = /.*(dt.entity.host|dt.entity.process_group_instance|dt.trace_sampled|dt.trace_id|dt.span_id): ([^ ]+)( - )?/
      LOGLEVEL_REGEXP = /(?<level>INFO|WARN|ERROR|FATAL)/

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

      def parse_syslog(line)
        m = line.match(HTTPS_REGEXP)

        record = m.names.each_with_object({}) do |name, rec|
          rec[name] = m[name]

          # Process 'pri' field
          next unless name == 'pri'

          pri = m[name].to_i
          # Split PRIVAL into Facility and Severity
          rec['facility'] = FACILITY_MAP[pri >> FACILITY_SHIFT]
          rec['loglevel'] = PRIORITY_MAP[pri & PRIORITY_MASK]
        end
        record.delete('pri')
        record
      end

      def extract_dt_meta(record)
        dt_match = record['message'].match(DYNATRACE_FIELDS_REGEXP)
        dt_match&.named_captures&.each do |name, val|
          record[name] = val
        end
        record
      end

      def override_loglevel(record)
        loglevel_match = record['message'].match(LOGLEVEL_REGEXP)
        record['loglevel'] = loglevel_match['level'] unless loglevel_match.nil?
        record
      end

      def enforce_utf8(record)
        record['message'] = record['message'].force_encoding('UTF-8')
        record
      end

      def strip_dt_meta(record)
        record['message'] = record['message'].gsub(DYNATRACE_META_SECTION, '')
        record
      end

      def parse(text)
        records = text.split("\n").map do |line|
          rec = parse_syslog(line)
          rec = override_loglevel(rec)
          rec = enforce_utf8(rec)
          rec = extract_dt_meta(rec)
          rec = strip_dt_meta(rec)
          rec
        end
        log.info("Parsed #{records.count} records.")
        yield nil, records
      end
    end
  end
end
