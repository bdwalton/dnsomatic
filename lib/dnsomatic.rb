require 'yaml'
require 'open-uri'

module DNSOMatic
  VERSION = 0.1
  USERAGENT = "Ruby_DNS-o-Matic/#{VERSION}"

  class Error < Exception; end #just for a unique name, more than anything else.

  def self.http_fetch (url)
    uri = URI.parse(url)

    begin
      res = if uri.user and uri.password
	      open(url, 'User-Agent' => USERAGENT,
		:http_basic_authentication => [uri.user, uri.password])
	    else
	      open(url, 'User-Agent' => USERAGENT)
	    end
      res.read
    rescue OpenURI::HTTPError, SocketError => e
      msg = "Error communicating with #{uri.host}\n"
      msg += "Message was: #{e.message}\n"
      msg += "Full URL being requested: #{uri}"
      raise(DNSOMatic::Error, msg)
    end
  end

  def self.yaml_read(file)
    begin
      yaml = YAML::load(File.open(file))
    rescue Exception => e
      msg = "An exception (#{e.class}) occurred while reading a yaml file: #{file}\n"
      msg += "The error message is: #{e.message}"
      raise(DNSOMatic::Error, msg)
    end
  end

  def self.yaml_write(file, data)
    begin
      File.open(file, 'w') do |f|
	f.puts data.to_yaml
      end
    rescue Exception => e
      msg = "An exception (#{e.class}) occurred while writing a yaml file: #{file}\n"
      msg += "The error message is: #{e.message}"
      raise(DNSOMatic::Error, msg)
    end
  end
end

require 'dnsomatic/opts'
require 'dnsomatic/config'
require 'dnsomatic/updater'
require 'dnsomatic/iplookup'
require 'dnsomatic/logger'
