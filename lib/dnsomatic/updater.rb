
module DNSOMatic
  # This is the primary interface used to perform updates of IP information
  # to the DNS-o-Matic service.
  class Updater
    # Initialize and updater object with a set of config options.  config is
    # a hash that must contain the following keys:
    # * hostname: a string representing the hostname to be updated
    # * mx: a string representing a valid MX for hostname
    # * backmx: a string representing a secondary MX for hostname
    # * username: the username with rights to update hostname
    # * password: the corresponding password
    # * webipfetchurl: a url that returns the IP of the system requesting the it
    # * offline: determines whether 'offline' mode should be used.
    def initialize(config)
      @config = config
      #use a cache in case other host stanzas have already looked up
      #our ip using the same remote agent.
      @lookup = DNSOMatic::IPLookup.instance
    end

    # Build and send the url that is passed to the DNS-o-Matic system to
    # request an update for the hostname provided in the configuration.
    # By default, the we'll honour the changed? status of the IPStatus object
    # returned to us, but if force is set to true, we'll send the update
    # request anyway.
    def update(force = false) url = upd_url()

      if !@ipstatus.changed? and !force
	Logger::log("No change in IP detected for #{@config['hostname']}.  Not updating.")
      else
	Logger::alert("Updating IP for #{@config['hostname']} to #{@ipstatus.ip}.")
	update = DNSOMatic::http_fetch(url)

	if !update.match(/^good\s+#{@ipstatus.ip}$/)
	  msg = "Error updating host definition for #{@config['hostname']}\n"
	  msg += "Results:\n#{update}\n"
	  msg += "Error codes at: https://www.dnsomatic.com/wiki/api"
	  raise(DNSOMatic::Error, msg)
	end
      end

      true
    end

    # A simple wrapper around update that sets force to true.  The forceful
    # nature of the update is logged if verbosity is enabled.
    def update!
      Logger::log("Forcing update at user request.")
      update(true)
    end

    # This is used to simply return the url that would be sent to DNS-o-Matic.
    # Using this is an easy way to build a list of update URL's that could
    # be directed elsewhere (a log, or wget, etc).
    def to_s
      upd_url
    end
	
    private
    def upd_url
      opt_params = %w(wildcard mx backmx offline)
      u = @config['username']
      p = @config['password']
      @ipstatus = @lookup.ip_from_url(@config['webipfetchurl'])

      #we'll use nil as a key from the ip lookup to determine that the ip
      #hasn't changed, so no update is required.
      url = "https://#{u}:#{p}@updates.dnsomatic.com/nic/update?"
      name_ip = "hostname=#{@config['hostname']}&myip=#{@ipstatus.ip}"
      url += opt_params.inject(name_ip) do |params, curp|
	val = @config[curp]
	next if val.eql?('') or val.nil?
	params += "&#{curp}=#{val}"
      end
      url
    end
  end
end #end module
