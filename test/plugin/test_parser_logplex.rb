# https://docs.fluentd.org/plugin-development/api-plugin-parser#writing-tests

require 'test/unit'
require 'fluent/test/driver/parser'

# Your own plugin
require 'fluent/plugin/parser_logplex'

class ParserLogplexTest < Test::Unit::TestCase
  def setup
    # Common setup
  end

  CONFIG = %().freeze

  def create_driver(conf = CONF)
    Fluent::Test::Driver::Parser.new(Fluent::Plugin::Logplex).configure(conf)
  end

  sub_test_case 'plugin will parse syslog format' do
    test 'record has a field' do
      d = create_driver(CONFIG)
      text = '59 <13>1 2022-01-26T06:25:52.589365+00:00 host app web.1 - foo'
      expected_records = [{
        'drain_id' => 'host',
        'facility' => 'user',
        'ident' => 'app',
        'loglevel' => 'notice',
        'message' => 'foo',
        'pid' => 'web.1',
        'time' => '2022-01-26T06:25:52.589365+00:00'
      }]
      d.instance.parse(text) do |_time, records|
        assert_equal(expected_records, records)
      end
    end
  end

  keys_to_extract = ['dt.entity.host', 'dt.entity.process_group_instance', 'trace_id', 'span_id']

  sub_test_case 'plugin will parse dynatrace metadata' do
    test 'record has dynatrace metadata' do
      d = create_driver(CONFIG)
      text = '59 <13>1 2022-01-26T06:25:52.589365+00:00 host app web.1 - dt.entity.host: 12345, dt.entity.process_group_instance: 4321, dt.trace_id: abcd, dt.span_id: dcba - more stuff here'
      d.instance.parse(text) do |_time, records|
        assert_equal(
          [{ 'message' => 'more stuff here' }],
          records.map { |record| record.select { |key, _| ['message'].include? key } }
        )
        assert_equal(
          [{ 'dt.entity.host' => '12345',
             'dt.entity.process_group_instance' => '4321',
             'trace_id' => 'abcd',
             'span_id' => 'dcba' }],
          records.map { |record| record.select { |key, _| keys_to_extract.include? key } }
        )
      end
    end
  end

  sub_test_case 'plugin will parse dynatrace metadata in another order, and with unexpected key value pairs present' do
    test '' do
      d = create_driver(CONFIG)
      text = '59 <13>1 2022-01-26T06:25:52.589365+00:00 host app web.1 - dt.entity.process_group_instance: 4321, dt.trace_sampled: true, dt.trace_id: abcd, dt.span_id: dcba, dt.entity.host: 12345 - more stuff here'
      d.instance.parse(text) do |_time, records|
        assert_equal(
          [{ 'message' => 'more stuff here' }],
          records.map { |record| record.select { |key, _| ['message'].include? key } }
        )
        assert_equal(
          [{ 'dt.entity.host' => '12345',
             'dt.entity.process_group_instance' => '4321',
             'trace_id' => 'abcd',
             'span_id' => 'dcba' }],
          records.map { |record| record.select { |key, _| keys_to_extract.include? key } }
        )
      end
    end
  end
end
