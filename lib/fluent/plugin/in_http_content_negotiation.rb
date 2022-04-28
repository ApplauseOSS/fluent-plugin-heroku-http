# frozen_string_literal: true

require 'fluent/plugin/in_http'

module Fluent
  module Plugin
    class ContentTypeParser < Parser
      Fluent::Plugin.register_parser('content_type_parser', self)

      config_set_default :time_key, 'time'

      config_section :parser, multi: true, required: true do
        config_param :content_type, :string
        config_param :parse, :string
      end

      def initialize
        super
        @content_type_parsers = {}
      end

      def configure(conf)
        super

        @parser.each do |parser_config|
          parser = Plugin.new_parser(parser_config.parse)
          parser.configure(parser_config.corresponding_config_element)
          @content_type_parsers[parser_config.content_type] = parser
        end

        log.info('Content type parsers:', @content_type_parsers.to_s)
      end

      def parse(content_type, text)
        parser_for_type = @content_type_parsers[content_type]
        log.debug("Parser for #{content_type} = #{parser_for_type}")
        tyme, records = parser_for_type.parse(text) { |tyme, records| return tyme, records }
        log.info("time is #{tyme}")
        yield tyme, records
      end
    end

    class HttpContentNegotiationInput < HttpInput
      Fluent::Plugin.register_input('http_content_negotiation', self)

      helpers :parser

      def configure(conf)
        super
        @parser = parser_create
      end

      def parse_params_with_parser(params)
        content_type = params['HTTP_CONTENT_TYPE']
        payload = params['_event_record']
        tyme, records = @parser.parse(content_type, payload) { |tyme, records| return tyme, records }
        [tyme, records]
      end
    end
  end
end
