require 'singleton'
require 'date'

module DNSOMatic
  class IPStatus
    CHANGED = true
    UNCHANGED = false

    attr_reader :ip
    def initialize(ip, status)
      if !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
	msg = "Strange return value from IP Lookup service: #{url}\n"
	msg += "Body of HTTP response was:\n"
	msg += ip
	raise(DNSOMatic::Error, msg)
      end
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

    attr_accessor :persist

    def initialize
      fn = 'dnsomatic-' + Process.uid.to_s + '.cache'
      @cache_file = File.join(ENV['TEMP'] || '/tmp', fn)

      @cache = {}
      @persist = true
    end

    def setcachefile(file)
      raise(DNSOMatic::Error, "Unwritable cache file") unless File.writable?(File.dirname(file))
      @cache_file = file
    end

    def ip_for(url)
      load()
      #implement a simple cache to prevent making multiple http requests
      #to the same remote agent (in the case where a user defines multiple
      #updater stanzas that use the same ip fetch url).
      if min_not_elapsed(url)
	ip = @cache[url][:ip]
	stat, time = [IPStatus::UNCHANGED, @cache[url][:time]]
	Logger::log("Returned cached IP #{ip} from #{url}")
      elsif max_elapsed(url)  #force updates to happen if no change in Xsec
	ip = DNSOMatic::http_fetch(url) #poll just in case it has changed too
	#we always set an updated time here so that min and max play nicely on
	#future updates.
	stat, time = [IPStatus::CHANGED, Time.now]
	Logger::log("Forcing update of IP #{ip} from #{url} due\nto elapsed maximum update interval (#{$opts.maximum}s).")
      else  #unknown or potentially changed
	prev_ip = @cache[url].nil? ? '' : @cache[url][:ip]
	ip = DNSOMatic::http_fetch(url)
	stat, time = case ip
	      when prev_ip: [IPStatus::UNCHANGED, @cache[url][:time]]
	      else [IPStatus::CHANGED, Time.now]
	    end
	Logger::log("Feched IP #{ip} from #{url} (#{stat.eql?(IPStatus::CHANGED) ? 'changed' : 'unchanged'})")
      end

      @cache[url] = { :ip => ip, :time => time }
      save()  #ensure that we get spooled to disk.
      IPStatus.new(ip, stat)
    end

    private
    def min_not_elapsed(url)
      Time.now - (@cache[url][:time] || Time.now) <= $opts.minimum
    end

    def max_elapsed(url)
      Time.now - (@cache[url][:time] || Time.now) >= $opts.maximum
    end

    def load
      if File.exists?(@cache_file) and @persist
	@cache = DNSOMatic::yaml_read(@cache_file)
      end
    end

    def save
      DNSOMatic::yaml_write(@cache_file, @cache) if @persist 
    end
  end
end
