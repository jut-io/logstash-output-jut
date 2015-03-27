require "spec_helper"
require "logstash/outputs/batch_http"
require "logstash/codecs/plain"
require "logstash/event"

describe LogStash::Outputs::batchHttp do
  let(:batch_http_config) {
    {
      'url' => 'http://localhost:9000/'
    }
  }
  let(:sample_event) { LogStash::Event.new({'message' => 'hello', '@timestamp'=>LogStash::Timestamp.now}) }

  context 'when intializing' do
    it 'should register' do
      output = LogStash::Outputs::batchHttp.new(batch_http_config)
      expect {output.register}.to_not raise_error
    end

    it 'should populate batch_http config with default values' do
      batchHttp = LogStash::Outputs::batchHttp.new(batch_http_config)
      insist {batchHttp.url} == 'http://localhost:9000/'
      insist {batchHttp.interval} == 1
      insist {batchHttp.limit} == 200
      insist {batchHttp.threads} == 5
      insist {batchHttp.verbose} == false
    end
  end
end
