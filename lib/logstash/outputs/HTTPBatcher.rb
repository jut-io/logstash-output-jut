# encoding: utf-8
require "logstash/namespace"
require "json"
require 'thread'
require "ftw"
require "uri"

class LogStash::Outputs::HTTPBatcher
  def initialize(url, interval, logger, headers, limit, threads, verbose)
    @mutex = Mutex.new
    @headers = headers
    @content_type = "application/json"
    @url = url
    @queue = []
    @interval = interval
    @logger = logger
    @req_threads = Array.new(threads) { create_thread() }
    @sent = 0 # For debugging use
    @limit = limit
    @verbose = verbose
  end # def initialize

  def receive(event)
    @mutex.synchronize do
      @queue << event
    end
  end # def receive

  def create_thread
    # Creates a thread that makes a request at the given interval
    return Thread.new do
      Thread.current["agent"] = FTW::Agent.new
      loop do
        time = make_request
        if @verbose
          if time > 0
            puts "Request time: #{time.to_s}"
          end
        end
        if time < @interval
          sleep(@interval - time)
        end
      end
    end
  end # def create_thread

  def make_request
    return -1 if @queue.empty?
    beginning = Time.now
    request = Thread.current["agent"].post(@url)
    request["Content-Type"] = @content_type
    if @headers
      @headers.each do |k,v|
        request.headers[k] = v
      end
    end
    Thread.current["queue"] = []
    @mutex.synchronize do
      # Moves the first @limit number of events into the current thread queue
      Thread.current["queue"] = @queue.shift(@limit)
      @sent = @sent + Thread.current["queue"].size
      if @verbose
        puts "Sent: #{@sent.to_s}, Remaining: #{@queue.size}"
      end
    end
    if !Thread.current["queue"].empty?
      request.body = Thread.current["queue"].to_json
      response = Thread.current["agent"].execute(request)
      rbody = response.read_body
    end
    end_time = Time.now
    time_elapsed = end_time - beginning
    return time_elapsed
  rescue Exception => e
    if @verbose
      @logger.warn("Unhandled exception", :request => request, :exception => e, :stacktrace => e.backtrace)
    else
      @logger.warn("Unhandled exception", :host => request["host"], :exception => e, :stacktrace => e.backtrace)
    end
    return -1
  end # def make_request
end
