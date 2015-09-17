require "spec_helper"
require "logstash/outputs/jut"
require "logstash/codecs/plain"
require "logstash/event"

describe LogStash::Outputs::Jut do
  let(:jut_config) {
    {
      'url' => 'http://localhost:9000/'
    }
  }
  let(:sample_event) { LogStash::Event.new({'message' => 'hello', '@timestamp'=>LogStash::Timestamp.now}) }

  context 'when intializing' do
    it 'should register' do
      output = LogStash::Outputs::Jut.new(jut_config)
      expect {output.register}.to_not raise_error
    end

    it 'should populate jut config with default values' do
      cfg = LogStash::Outputs::Jut.new(jut_config)
      insist {cfg.url} == 'http://localhost:9000/'
      insist {cfg.interval} == 1
      insist {cfg.limit} == 200
      insist {cfg.threads} == 5
      insist {cfg.verbose} == false
    end
  end
end
