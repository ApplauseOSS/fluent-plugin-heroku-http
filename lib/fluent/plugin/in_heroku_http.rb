# frozen_string_literal: true

require 'fluent/plugin/in_http'

module Fluent
  module Plugin
    # FIXME: what to do with this?
    class ContentTypeParser < Parser
      Fluent::Plugin.register_parser('content_type_parser', self)
    end

    # FIXME: rename
    class HerokuHttpInput < HttpInput
      Fluent::Plugin.register_input('heroku_http', self)

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
      end

      def parse_params_with_parser(params)
        content_type = params['HTTP_CONTENT_TYPE']
        parser = @content_type_parsers[content_type]
        tyme, records = parser.parse(params['_event_record']) do |time, records|
          return time, records
        end
        puts records.to_s

        [tyme, records]
      end
    end
  end
end
