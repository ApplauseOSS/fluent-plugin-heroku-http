require 'fluent/plugin/in_syslog'
require 'fluent/plugin/in_http'
require_relative 'parser_logplex'

module Fluent
  module Plugin
    class HerokuHttpInput < HttpInput
      Fluent::Plugin.register_input('heroku_http', self)

      config_param :drain_ids, :array, default: nil

      config_section :parse do
        config_set_default :@type, 'logplex'
      end

      def parse_params_with_parser(params)
        drain_id = params['HTTP_LOGPLEX_DRAIN_TOKEN']

        if @drain_ids.nil? || @drain_ids.include?(drain_id)
          _time, records = super

          records.each do |record|
            record['drain_id'] = drain_id
          end

          [_time, records]
        else
          log.warn("drain_id #{drain_id.inspect} is not in #{@drain_ids.inspect}.")

          [nil, []]
        end
      end
    end
  end
end
