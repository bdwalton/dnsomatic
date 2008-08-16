
module DNSOMatic
  class Updater
    def initialize(config)
      @config = config
      #use a cache in case other host stanzas have already looked up
      #our ip using the same remote agent.
      @ipcache = DNSOMatic::IPFetchCache.instance
    end

    def update(force = false)
      url, status = upd_url()

      if status.eql?('unchanged') and !force
	$stdout.puts "No change detected in IP.  Not updating." if $opts.verbose
      else
	$stdout.puts "Updating IP for #{@config['hostname']}." if $opts.verbose
	update = DNSOMatic::HTTPAgent.fetch(url)

	if !update.match(/^good\s+#{@ip}$/)
	  msg = "Error updating host definition for #{@config['hostname']}\n"
	  msg += "Results:\n#{update}\n"
	  msg += "Error codes at: https://www.dnsomatic.com/wiki/api"
	  raise DNSOMatic::UpdErr, msg
	end
      end
    end

    def update!
      $stdout.puts "Forcing update due to use of -f." if $opts.verbose
      update(true)
    end

    def to_s
      upd_url[0]
    end
	
    private
    def upd_url
      opt_params = %w(wildcard mx backmx offline)
      u = @config['username']
      p = @config['password']
      ip, status = @ipcache.ip_for(@config['webipfetchurl'])
      @ip = ip

      #we'll use nil as a key from the ip lookup to determine that the ip
      #hasn't changed, so no update is required.
      url = "https://#{u}:#{p}@updates.dnsomatic.com/nic/update?"
      name_ip = "hostname=#{@config['hostname']}&myip=#{ip}"
      url += opt_params.inject(name_ip) do |params, curp|
	val = fmt(@config[curp])
	next if val.eql?('') or val.nil?
	params += "&#{curp}=#{val}"
      end
      [url, status]
    end
	
    def fmt(val)
      #because YAML interprets a raw YES or NO as a boolean true/false and we
      #don't want to burden user with prefixing the value with !str, we'll
      #attempt to deduce what they meant here...
      if [TrueClass, FalseClass].include?(val.class)
	val ? 'YES' : 'NO'
      elsif val.kind_of?(NilClass)
	'NOCHG'
      else
	val.to_s
      end
    end
  end
end #end module
