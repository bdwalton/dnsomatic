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

  class IPFetchCache
    include Singleton

    def initialize(altfn = nil)
      if altfn.nil?
	fn = 'dnsomatic-' + Process.uid.to_s + '.cache'
      else
	fn = altfn
      end
      @@cache_file = File.join(ENV['TEMP'] || '/tmp', fn)

      @@ip_fetch_map = {}

      if File.exists?(@@cache_file)
	@@ip_fetch_map = DNSOMatic::yaml_read(@@cache_file)
      end
    end

    def ip_for(url)
      #implement a simple cache to prevent making multiple http requests
      #to the same remote agent (in the case where a user defines multiple
      #updater stanzas that use the same ip fetch url).
      if @@ip_fetch_map[url].nil?
	upd = 'unknown'
      elsif Time.now - @@ip_fetch_map[url][:time] >= $opts.interval
	upd = 'expired'
	prev_ip = @@ip_fetch_map[url][:ip]
      else
	upd = 'cached'
      end

      case upd
      when /unknown|expired/:
	$stdout.puts "Doing IP fetch from #{url} (#{upd})" if $opts.verbose
	ip = DNSOMatic::http_fetch(url)

	if !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
	  msg = "Strange return value from IP Lookup service: #{url}\n"
	  msg += "Body of HTTP response was:\n"
	  msg += ip
	  raise(DNSOMatic::Error, msg)
	end

	@@ip_fetch_map[url] = { :ip => ip, :time => Time.now }
	if upd.eql?('expired') and ip.eql?(prev_ip)
	  IPStatus.new(ip, DNSOMatic::IPStatus::UNCHANGED)
	else
	  IPStatus.new(ip, DNSOMatic::IPStatus::CHANGED)
	end
      else
	ip = @@ip_fetch_map[url][:ip]
	$stdout.puts "Returned cached IP #{ip} from #{url}" if $opts.verbose
	IPStatus.new(ip, DNSOMatic::IPStatus::UNCHANGED)
      end
    end

    def save
      DNSOMatic::yaml_write(@@cache_file, @@ip_fetch_map)  
    end
  end
end
