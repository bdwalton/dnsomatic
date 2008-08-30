require 'net/https'

module DNSOMatic
  # A class to handle 'parsing' the configuration files and setting defaults
  # as required.  Config files are actually YAML files, so the parsing is
  # offloaded for the most part.
  class Config
    #in most cases, a user can simply set username and password in a defaults:
    #stanza and fire the client.
    @@defaults = { 'hostname' => 'all.dnsomatic.com',
		   'wildcard' => 'NOCHG',
		   'mx' => 'NOCHG',
		   'backmx' => 'NOCHG',
		   'offline' => 'NOCHG',
		   'webipfetchurl' => 'http://myip.dnsomatic.com/' }

    # Create a new instance with the option of specifying an alternate config
    # file to read.  The default config file is either $HOME/.dnsomatic.cf (on
    # unix or if Windows specifies a $HOME environment variable) or
    # %APPDATA%/.dnsomatic.cf for most Windows environments.
    def initialize(conffile = nil)
      stdcf = File.join(ENV['HOME'] || ENV['APPDATA'], '.dnsomatic.cf')
      if conffile
	if File.exists?(conffile)
	  @cf = conffile
	else
	  raise(DNSOMatic::Error, "Invalid config file: #{conffile}")
	end
      elsif File.exists?(stdcf)
	@cf = stdcf
      else
	#in this case, the values from the defaults: stanza in the default conf
	#will provide all values required.
	@cf = nil
      end

      raise(DNSOMatic::Error, 'No config file available.  Try creating #{stdcf}.') unless @cf

      @updaters = nil
      @config = {}

      # the user config must supply values for these, either in a specific
      # host updater stanza or by overriding the global default in defaults:
      @req_conf = %w(username password)

      load()
    end

    # Provide a view of the configuration file after merging defaults.  This
    # is returned as a YAML string, suitable for redirecting right into a
    # config file.  Optionally, the return value can be 'pruned' to show only
    # one host update stanza by passing in the desired name as a string.
    def merged_config(prune_to = nil)
      prune_to.nil? ? @config.to_yaml : one_key(@config, prune_to).to_yaml
    end

    # Return a list of Updater objects.  Each host update stanza is turned into
    # an individual object.  This may be pruned to a single Updater by passing
    # in the name of the stanza title.
    def updaters(prune_to = nil)
      #don't create updater objects until they're actually requested.
      #(saves a little overhead if just displaying the config)
		      
      if @updaters.nil?
	@updaters = {}
	@config.each_key do |token|
	  @updaters[token] = Updater.new(@config[token])
	end
      end

      prune_to.nil? ? @updaters : one_key(@updaters, prune_to)
    end

    private

    def one_key(hsh, key)
      if ! hsh.has_key?(key)
	msg = "Invalid host stanza filter ('#{key}').\n"
	msg += "You config doesn't define anything with that name."
	raise(DNSOMatic::ConfErr, msg)
      else
	{ key => hsh[key] }
      end
    end

    def load
      conf = DNSOMatic::yaml_read(@cf)
      raise DNSOMatic::Error, "Invalid configuration format in #{@cf}" unless conf.kind_of?(Hash)

      if conf.has_key?('defaults')
	#allow the user to override our built-in defaults
	@@defaults.merge!(conf['defaults'])
	#if they've provided only the defaults stanza, we'll use it to perform
	#the update, otherwise remove it as it has been folded into @@defaults
	conf.delete('defaults') if conf.keys.size > 1
      end

      conf.each_key do |token|
	stanza = @@defaults.merge(conf[token])
	@req_conf.each do |required|
	  #still test for existence in case the defaults get munged.
	  if !stanza.has_key?(required) or stanza[required].nil?
	    msg = "Invalid configuration for Host Updater named '#{token}'\n"
	    msg += "Please define the field: #{required}."
	    raise(DNSOMatic::Error, msg)
	  end
	end

	#just in case
	stanza.each_pair do |k,v|
	  stanza[k] = fmt(v)
	end

	#save our merged version in case we're just dump our config to stdout
	@config[token] = stanza
      end
    end

    def fmt(val)
      #because YAML interprets a raw YES or NO as a boolean true/false and we
      #don't want to burden user with prefixing the value with !str, we'll
      #attempt to deduce what they meant here...
      if [TrueClass, FalseClass].include?(val.class)
	val ? 'ON' : 'OFF'
      elsif val.kind_of?(NilClass)
	'NOCHG'
      elsif val.kind_of?(String)
	case val.downcase
	  when 'no': 'OFF'
	  when 'yes': 'ON'
	  else val.gsub(/\s+/, '')
	end
      else
	val.to_s.gsub(/\s+/, '')
      end
    end
  end
end
