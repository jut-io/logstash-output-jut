# encoding: utf-8
require "logstash/namespace"
require "json"
require 'thread'
require 'typhoeus'
require "uri"

class LogStash::Outputs::HTTPBatcher
  def initialize(url, interval, logger, headers, limit, threads, verbose)
    @mutex = Mutex.new
    @headers = headers
    @content_type = "application/json"
    @url = url
    @queue = []
    @interval = interval
    @hydra = Typhoeus::Hydra.new(max_concurrency: 100)
    @logger = logger
    @req_threads = Array.new(threads) { create_thread() }
    @sent = 0 # For debugging use
    @limit = limit
    @verbose = verbose
    @request_thread = hydra_thread()
  end # def initialize

  def receive(event)
    @mutex.synchronize do
      @queue << event
    end
  end # def receive

  def hydra_thread
    return Thread.new do 
      loop do
        @hydra.run
      end
    end
  end

  def create_thread
    # Creates a thread that makes a request at the given interval
    return Thread.new do
      loop do
        time = make_request
        if @verbose && time > 0
          puts "Time to queue request: #{time.to_s}"
        end
        if time < @interval
          sleep(@interval - time)
        end
      end
    end
  end # def create_thread

  def make_request
    return 0 if @queue.empty?
    beginning = Time.now
    headers = {}
    headers["Content-Type"] = @content_type
    headers["Accept"] = @content_type
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
      body = Thread.current["queue"].to_json
      request = Typhoeus::Request.new(
        @url,
        method: :post,
        body: body,
        headers: headers
      )
      request.on_complete do |response|
        if @verbose
          puts "Total time: #{response.total_time}, Connect Time: #{response.connect_time}, Transfer Started: #{response.starttransfer_time}"
        end
      end
      @hydra.queue(request)
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
  end # def make_request
end
