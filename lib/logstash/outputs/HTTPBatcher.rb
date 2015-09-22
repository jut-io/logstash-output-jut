# encoding: utf-8
require "logstash/namespace"
require "json"
require "thread"
require "work_queue"
require "net/https"
require "openssl"
require "uri"

class LogStash::Outputs::HTTPBatcher
  def initialize(url, idle_flush, logger, headers, limit, nthreads, verbose)
    @url = URI.parse(url)
    @idle_flush = idle_flush
    @logger = logger
    @headers = headers
    @limit = limit
    @verbose = verbose

    @content_type = "application/json"
    @stopped = false

    @queue_mutex = Mutex.new
    @queue = []

    @flush_time = nil
    @flush_thread = create_flush_thread()
    @work_queue = WorkQueue.new nthreads, nil
  end # def initialize

  def stop
    if @verbose
      puts "stopping batcher (have #{@queue.size()} queued message)"
    end

    @stopped = true
    while @queue.size() > 0 do
      enqueue_batch
    end

    @flush_thread.join
    @work_queue.join
  end

  def receive(event)
    size = 0
    @queue_mutex.synchronize do
      @queue << event
      size = @queue.size
    end

    if size >= @limit
      enqueue_batch
    end

    @flush_time = Time.now + @idle_flush
  end # def receive

  def create_flush_thread
    return Thread.new do
      while !@stopped do
        now = Time.now
        if @flush_time != nil && @flush_time <= now
          enqueue_batch
          @flush_time = nil
        end

        sleep(@flush_time == nil ? @idle_flush : @flush_time - now)
      end
    end
  end

  def enqueue_batch
    tosend = []
    @queue_mutex.synchronize do
      tosend = @queue.shift(@limit)
    end

    if tosend.size > 0
      @work_queue.enqueue_b do
        send_batch tosend
      end
    end
  end

  def send_batch(tosend)
    connection = Thread.current["connection"]
    if connection == nil
      if @verbose
        puts "creating new https connection"
      end

      connection = Net::HTTP.new(@url.host, @url.port)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
      Thread.current["connection"] = connection
    end

    beginning = Time.now
    request = Net::HTTP::Post.new(@url.request_uri)

    request["Content-Type"] = @content_type
    if @headers
      @headers.each do |k,v|
        request.headers[k] = v
      end
    end
    
    if @verbose
      puts "posting #{tosend.size} records"
    end

    request.body = tosend.to_json
    response = connection.request request

    status = response.code
    rbody = response.read_body

    if status != "200"
      raise "POST failed with status #{status} (#{rbody})"
    end

    if @verbose
      time = Time.now - beginning
      puts "POST response in #{time.to_s} #{status} #{rbody}"
    end

  rescue Exception => e
    if @verbose
      @logger.warn("Unhandled exception", :request => request, :exception => e, :stacktrace => e.backtrace)
    else
      @logger.warn("Unhandled exception", :host => request["host"], :exception => e, :stacktrace => e.backtrace)
    end
  end
end
