require 'yaml'
require 'open-uri'

# :title: dnsomatic - a DNS-o-Matic update client
#
# = dnsomatic - a DNS-o-Matic update client
#
# Author:: Ben Walton (mailto: bdwalton@gmail.com)
# Copyright:: Copyright (c) 2008 Ben Walton
# License:: GNU General Public License (GPL) version 3
#
# = Summary
#
# By default, dnsomatic tries to avoid polling or updating its address too
# often.  It will not check a remote IP lookup url more often than every half
# hour.  It will avoid updating DNS-o-Matic for up to 15 days if the IP
# detected hasn't changed.
#
# = Configuration
#
# Configuration is specified by a small YAML file with a default location
# of $HOME/.dnsomatic.cf
#
# A basic configuration can be as simple as:
#   defaults:
#     username: YOUR_DNSOMATIC_USERNAME
#     password: YOUR_DNSOMATIC_PASSWORD
#
# The dnsomatic client may update all of your registered DNS-o-Matic names
# in one shot or individual names one at a time.  The defaults: stanza in the
# configuration provides default values for any hostname update stanzas to
# follow, although no extra stanzas are required.
#
# To provide alternate stanzas, add items in your config like:
#   myhost:
#     hostname: myhost.dyndns.foo
#     mx: mx.example.net
#
# When that stanza is used in conjunction with the above defaults stanza, you
# have a fully operation host update definition (myhost: would inherit the
# username and password from defaults:)
#
# In some cases it may be desirable to fetch the Web visible IP for a system
# from a different URL than the dnsomatic option (http://myip.dnsomatic.com).
# To allow for this, you may add a webipfetchurl: paramter to a confiruation
# stanza (or defaults:).  Consider:
#   otherhost:
#     hostname: otherhost.dyndns.foo
#     webipfetchurl: http://ipfetch.example.net/
#
# If all three of the above stanzas were in the same configuration file, you
# would send two update requests (conditional upon changed IP addresses and/or
# expiration times), with the second polling for its IP at the
# ipfetch.example.net url instead of the default myip.dnsomatic.com service.
#
# When there are update stanzas named specifically (in addition to defaults:),
# defaults is used only to provide default values for the other stanzas.  For
# most users wanting to define more than one updater stanza, you would provide
# the username and password via the defaults: stanza and then a hostname value
# for the individual stanza definitions.  Once the defaults are merged into the
# specific stanzas, they are ignored.  To see how the merging works, you may
# use the 'display' option (see options with --help), which will dump to stdout
# a YAML serialized view of the merged configuration.
#
# This allows you to obtain an IP from multiple (or just alternate services).
# Although this might sound less than useful, it would be handy if you wanted
# different IP's associated with machines that could route to the internet via
# two different public IP's, or if you wanted to poll an internal service and
# update a public name with an internal IP.
#
# A complete list of options that may be specified in the defaults: or a named
# update definition are:
# * username - your dnsomatic username
# * password - your dnsomatic password
# * mx - a hostname that will handle mail delivery for this host.  it must
#   resolve to an IP or DNS-o-Matic will ignore it.
# * backmx - a lower priority mx record.  sames rules as mx.  you may also list
#		these as NOCHG, which tells DNS-o-Matic to leave them as is.
# * hostname - the hostname to update.  the defaults specify this as
#		all.dnsomatic.com, which tells dnsomatic to update all listed
#		records with the same values.
# * wildcard - indicates whether foo.hostname and bar.hostname and baz.hostname should also resolve to the same IP as hostname.
#		- ON = enable
#		- NOCHG = leave it as is
#		- _other_ = disable
# * offline - sets the hostname of offline mode, which may do some redirection
#		things depending on the service being updated.
#		- YES = enable
#		- NOCHG = leave it as is
#		- _other_ = disable
#
# = Usage
#
# Usage: dnsomatic [options]
#   -m, --minimum SEC                The minimum time between updates (def: 30m)
#   -M, --maximum SEC                The maximum time between updates (def: 15d)
#   -a, --alert                      Emit an alert if the IP is updated
#   -n, --name NAME                  Only update host stanza NAME
#   -d, --display-config             Display the configuration and exit
#   -c, --config FILE                Use an alternate config file
#   -f, --force                      Force an update, even if IP is unchanged
#   -p, --print                      Output the update URLs.  No action taken
#   -v, --verbose                    Display runtime messages
#   -V, --version                    Display version and exit
#   -x, --debug                      Output additional info in error situations
#   -h, --help                       Display this help text

module DNSOMatic
  VERSION = '0.2.0'
  USERAGENT = "Ruby_DNS-o-Matic/#{VERSION}"

  # We provide our easily distinguishable exception class so that we can easily
  # differntiate our errors from others.
  class Error < Exception; end

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
