require 'singleton'
require 'date'

module DNSOMatic
  class IPStatus
    CHANGED = true
    UNCHANGED = false

    attr_reader :ip
    def initialize(url)
      @url = url
      @status = CHANGED	#all new lookups are changed.
      @ip = getip()
      @last_update = Time.now
      Logger::log("Fetched new IP #{@ip} from #{@url}.")
    end

    def changed?
      @status
    end

    def update
      if min_elapsed?
	Logger::log("Returned cached IP #{@ip} from #{@url}.")
	@status = UNCHANGED
      else
	ip = getip()
	@last_update = @status ? Time.now : @last_update

	if !@ip.eql?(ip)
	  Logger::log("Detected IP change (#{@ip} -> #{ip}) from #{@url}.")
	else
	  Logger::log("No IP change detected from #{@url}.")
	end

	@status = (max_elapsed? or !@ip.eql?(ip)) ? CHANGED : UNCHANGED
	@ip = ip
      end
    end

    private
    def min_elapsed?
      if Time.now - @last_update <= $opts.minimum
	Logger::log("Minimum lookup interval not expired.")
	true
      else
	false
      end
    end

    def max_elapsed?
      if Time.now - @last_update >= $opts.maximum
	Logger::log("Maximum interval between updates has elapsed.  Update will be forced.")
	true
      else
	false
      end
    end

    def getip
      ip = DNSOMatic::http_fetch(@url)
      if !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
	msg = "Strange return value from IP Lookup service: #{@url}\n"
	msg += "Body of HTTP response was:\n"
	msg += ip
	raise(DNSOMatic::Error, msg)
      else
	ip
      end
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
      if !File.writable?(File.dirname(file))
	raise(DNSOMatic::Error, "Unwritable cache file directory.")
      elsif File.exists?(file) and !File.writable(file)
	raise(DNSOMatic::Error, "Unwritable cache file")
      end
      @cache_file = file
    end

    def ip_from_url(url)
      load()
      #implement a simple cache to prevent making multiple http requests
      #to the same remote agent (in the case where a user defines multiple
      #updater stanzas that use the same ip fetch url).
      if @cache[url]
	@cache[url].update
      #force updates to happen if no change in Xsec
      else  #unknown
	@cache[url] = IPStatus.new(url)
      end

      save()  #ensure that we get spooled to disk.
      @cache[url]
    end

    private
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
