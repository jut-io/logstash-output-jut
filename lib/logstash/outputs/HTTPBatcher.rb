# encoding: utf-8
require "logstash/namespace"
require "json"
require "thread"
require "net/https"
require "openssl"
require "uri"

class LogStash::Outputs::HTTPBatcher
  def initialize(url, interval, logger, headers, limit, threads, verbose)
    @mutex = Mutex.new
    @headers = headers
    @content_type = "application/json"
    @url = URI.parse(url)
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
      connection = Net::HTTP.new(@url.host, @url.port)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_PEER

      Thread.current["connection"] = connection

      loop do
        time = make_request
        if time < @interval
          sleep(@interval - time)
        end
      end
    end
  end # def create_thread

  def make_request
    return -1 if @queue.empty?
    beginning = Time.now
    request = Net::HTTP::Post.new(@url.request_uri)

    request["Content-Type"] = @content_type
    if @headers
      @headers.each do |k,v|
        request.headers[k] = v
      end
    end
    
    tosend = []
    @mutex.synchronize do
      # Moves the first @limit number of events into the current thread queue
      tosend = @queue.shift(@limit)
      @sent = @sent + tosend.size
      if @verbose
        puts "Sent: #{@sent.to_s}, Remaining: #{tosend.size}"
      end
    end
    if !tosend.empty?
      request.body = tosend.to_json
      response = Thread.current["connection"].request request

      status = response.code
      rbody = response.read_body

      if status != "200"
        raise "POST failed with status #{status} (#{rbody})"
      end


      if @verbose
        time = Time.now - beginning
        puts "POST response in #{time.to_s} #{status} #{rbody}"
      end
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
