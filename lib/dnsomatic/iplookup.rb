require 'singleton'
require 'date'

module DNSOMatic
  class IPStatus
    CHANGED = true
    UNCHANGED = false

    attr_reader :ip
    def initialize(ip, status)
      @ip = ip
      unless [CHANGED, UNCHANGED].include?(status) 
	raise DNSOMatic::Error, "Invalid Status for IP set."
      end
      @status = status
    end

    def changed?
      @status
    end
  end

  class IPLookup
    include Singleton

    def initialize
      fn = 'dnsomatic-' + Process.uid.to_s + '.cache'
      @cache_file = File.join(ENV['TEMP'] || '/tmp', fn)

      @fetch_map = {}

      if File.exists?(@cache_file)
	@fetch_map = DNSOMatic::yaml_read(@cache_file)
      end
    end

    def ip_for(url)
      #implement a simple cache to prevent making multiple http requests
      #to the same remote agent (in the case where a user defines multiple
      #updater stanzas that use the same ip fetch url).
      if @fetch_map[url] and Time.now - @fetch_map[url][:time] >= $opts.interval
	ip = @fetch_map[url][:ip]
	time = @fetch_map[url][:time]
	stat = IPStatus::UNCHANGED
	Logger::log("Returned cached IP #{ip} from #{url}")
      else  #unknown or expired
	prev_ip = @fetch_map[url].nil? ? '' : @fetch_map[url][:ip]
	ip = DNSOMatic::http_fetch(url)
	stat = ip.eql?(prev_ip) ? IPStatus::UNCHANGED : IPStatus::CHANGED
	time = ip.eql?(prev_ip) ? @fetch_map[url][:time] : Time.now
	Logger::log("Feched IP #{ip} from #{url}")
      end

      if !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
	msg = "Strange return value from IP Lookup service: #{url}\n"
	msg += "Body of HTTP response was:\n"
	msg += ip
	raise(DNSOMatic::Error, msg)
      end

      @fetch_map[url] = { :ip => ip, :time => time }
      save()  #ensure that we get spooled to disk.
      IPStatus.new(ip, stat)
    end

    private
    def save
      DNSOMatic::yaml_write(@cache_file, @fetch_map)  
    end
  end
end
