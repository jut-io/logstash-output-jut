# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/outputs/HTTPBatcher"

class LogStash::Outputs::Jut < LogStash::Outputs::Base
  # This output lets you batch JSON objects and POSTs them to
  # generic HTTP endpoints. This supports only sending JSON
  # and sends a request every X seconds.
  #
  # Additionally, you are given the option to customize
  # the headers.

  config_name "jut"
  milestone 1

  # URL to use
  config :url, :validate => :string, :required => :true

  # Minimum interval at which requests are made per thread
  config :interval, :validate => :number, :default => 1

  # Maximum number of events per request
  config :limit, :validate => :number, :default => 200

  # Number of concurrent threads making requests
  config :threads, :validate => :number, :default => 5

  # Headers, if necessary, in the form of a hash
  config :headers, :validate => :hash

  # Verbose error messages
  config :verbose, :validate => :boolean, :default => false

  public
  def register
    @batcher = LogStash::Outputs::HTTPBatcher.new(@url, @interval, @logger, @headers, @limit, @threads, @verbose)
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # logstash wants to create "@timestamp", but jut wants "time"
    # you could of course do this with a mutate filter but lets make
    # the common case easy...
    if event.include?('@timestamp')
      event['time'] = event.remove('@timestamp')
    end

    if event.include?('@version')
      event.remove('@version')
    end

    evt = event.to_hash
    @batcher.receive(evt)

  rescue Exception => e
    @logger.warn("Unhandled exception", :exception => e, :stacktrace => e.backtrace)
  end

  public
  def teardown
    if @verbose
      puts "tearing down jut output plugin"
    end

    @batcher.stop

    if @verbose
      puts "finished"
    end
  end
end
