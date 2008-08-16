require 'singleton'
require 'dnsomatic/http'
require 'date'

module DNSOMatic
  class IPFetchCache
    include Singleton

    def initialize
      fn = 'dnsomatic-' + Process.uid.to_s + '.cache'
      @@cache_file = File.join(ENV['TEMP'] || '/tmp', fn)

      @@ip_fetch_map = {}

      if File.exists?(@@cache_file)
	@@ip_fetch_map = DNSOMatic::YAMLWrap::read(@@cache_file)
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
	ip = DNSOMatic::HTTPAgent.fetch(url)

	if !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
	  msg = "Strange return value from IP Lookup service: #{url}\n"
	  msg += "Body of HTTP response was:\n"
	  msg += ip
	  raise DNSOMatic::HttpErr, msg
	end

	@@ip_fetch_map[url] = { :ip => ip, :time => Time.now }
	if upd.eql?('expired') and ip.eql?(prev_ip)
	  [ip, 'unchanged']
	else
	  [ip, 'changed']
	end
      else
	ip = @@ip_fetch_map[url][:ip]
	$stdout.puts "Returned cached IP #{ip} from #{url}" if $opts.verbose
	[ip, 'unchanged']
      end
    end

    def save
      DNSOMatic::YAMLWrap::write(@@cache_file, @@ip_fetch_map)  
    end
  end
end
