
module DNSOMatic
  class Updater
    def initialize(config)
      @config = config
      #use a cache in case other host stanzas have already looked up
      #our ip using the same remote agent.
      @lookup = DNSOMatic::IPLookup.instance
    end

    def update(force = false)
      url = upd_url()

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

    def update!
      Logger::log("Forcing update at user request.")
      update(true)
    end

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
