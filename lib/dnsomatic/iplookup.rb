require 'singleton'
require 'date'

module DNSOMatic
  # This class handles actually fetching the remotely (not necessarily internet)
  # visible IP for a provided URL.  It manages both a minimum delay between
  # checks (default 30m) and a maximum time before it reports a CHANGED status
  # regardless of the result from the remote ip lookup url.
  class IPStatus
    CHANGED = true
    UNCHANGED = false

    attr_reader :ip

    # A URL must be provided that returns the IP of the system that requests
    # the URL.  A commonly used example is http://www.whatismyip.org
    def initialize(url)
      @url = url
      @status = CHANGED	#all new lookups are changed.
      @ip = getip()
      @last_update = Time.now
      Logger::log("Fetched new IP #{@ip} from #{@url}.")
    end

    # Tell a client whether or not we have a different IP than the last time
    # we were asked.  This may be faked in the case where we've reached the
    # the maximum time we allow before forcing an update.
    def changed?
      @status
    end

    # Calling this method requests that we retrieve our IP from the remote URL
    # and potentially alter our status as returned by changed?.
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

  # Any callers wishing to use IPStatus objects should request them via an
  # instance of IPLookup.  IPLookup is a singleton object that will cache
  # IPStatus objects across sessions by persisting them to a YAML file.
  class IPLookup
    include Singleton

    # Allow a caller to toggle the cache on and off.
    attr_accessor :persist

    # Because we're a singleton, we don't take any initialization arguments.
    def initialize
      fn = 'dnsomatic-' + Process.uid.to_s + '.cache'
      @cache_file = File.join(ENV['TEMP'] || '/tmp', fn)

      @cache = {}
      @persist = true
    end

    # This allows callers to alter which file we will persist our cache of
    # IPStatus objects to.
    def setcachefile(file)
      if !File.writable?(File.dirname(file))
	raise(DNSOMatic::Error, "Unwritable cache file directory.")
      elsif File.exists?(file) and !File.writable(file)
	raise(DNSOMatic::Error, "Unwritable cache file")
      end
      @cache_file = file
    end

    # This is the method a caller would use to request and IPStatus object.
    # The url is passed to new() when the object is created or returned from
    # the cache.
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
