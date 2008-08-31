require 'resolv'

module DNSOMatic
  # A class to handle 'parsing' the configuration files and setting defaults
  # as required.  Config files are actually YAML files, so the parsing is
  # offloaded for the most part.
  class Config
    # Create a new instance with the option of specifying an alternate config
    # file to read.  The default config file is either $HOME/.dnsomatic.cf (on
    # unix or if Windows specifies a $HOME environment variable) or
    # %APPDATA%/.dnsomatic.cf for most Windows environments.
    def initialize(conffile = nil)
      stdcf = File.join(ENV['HOME'] || ENV['APPDATA'], '.dnsomatic.cf')
      @cf = conffile.nil? ? stdcf : conffile
      raise(DNSOMatic::Error, "Invalid config file: #{conffile}") unless  File.exists?(@cf)

      @updaters = nil
      @config = {}

      #in most cases, a user can simply set username and password in a defaults:
      #stanza and fire the client.
      @defaults = { 'hostname' => 'all.dnsomatic.com',
		    'wildcard' => 'NOCHG',
		    'mx' => 'NOCHG',
		    'backmx' => 'NOCHG',
		    'offline' => 'NOCHG',
		    'webipfetchurl' => 'http://myip.dnsomatic.com/' }

      @type_validators = { 'hostname' => 'host',
			    'wildcard' => 'on_nochg',
			    'mx' => 'host',
			    'backmx' => 'yes_nochg',
			    'offline' => 'yes_nochg',
			    'webipfetchurl' => 'url' }

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
	@defaults.merge!(conf['defaults'])
	#if they've provided only the defaults stanza, we'll use it to perform
	#the update, otherwise remove it as it has been folded into @defaults
	conf.delete('defaults') if conf.keys.size > 1
      end

      conf.each_key do |name|
	stanza = @defaults.merge(conf[name])

	#just in case
	stanza.each_pair do |k,v|
	  stanza[k] = fmt(v)
	end

	validate(name, stanza)

	#save our merged version in case we're just dump our config to stdout
	@config[name] = stanza
      end
    end

    def validate(name, stanza)
      #first, ensure we have the _required_ fields in an update def stanza
      %w(username password).each do |required|
	#still test for existence in case the defaults get munged.
	if !stanza.has_key?(required) or stanza[required].nil?
	  msg = "Invalid configuration for Host Updater named '#{name}'\n"
	  msg += "Please define the field: #{required}.\n"
	  raise(DNSOMatic::Error, msg)
	end
      end

      @type_validators.each do |field, validator|
	Validators.send(validator, field, stanza[field])
      end
	
      #the dnsomatic api spec indicates that mx/back mx can be either NOCHG
      #or a hostname that must resolve to an IP.
      %w(mx backmx).each do |mxtype|
	mxval = stanza[mxtype]
	next if mxval.eql?('NOCHG')

	begin
	  Resolv.getaddress(mxval)
	rescue Resolv::ResolvError => e
	  msg = "Invalid value for #{mxtype}.\n"
	  msg += "It must be either NOCHG or a valid hostname.\n"
	  msg += e.message + "\n"
	  raise(DNSOMatic::Error, msg)
	end
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

  class Validators
    def self.host(field, val)
      $stderr.puts "Validating #{field} with #{val} using Validators.host"
      return true if val.eql?('NOCHG')
      return true if val.match(/[^\s]+\.[^\s]+/)  #no great, but workable
      msg = "Invalid hostname defined for #{field}.\n"
      msg += "You gave: #{val}\n"
      raise(DNSOMatic::Error, msg)
    end

    def self.yes_nochg(field, val)
      $stderr.puts "Validating #{field} with #{val} using Validators.yes_nochg"
      valid = %w(YES NO NOCHG)
      return true if valid.include?(val.upcase)
      msg = "Invalid value for #{field}.\n"
      msg += "It should be one of: #{valid.join(', ')}\n"
      msg += "You gave: #{val}\n"
      raise(DNSOMatic::Error, msg)
    end

    def self.on_nochg(field, val)
      $stderr.puts "Validating #{field} with #{val} using Validators.on_nochg"
      valid = %w(ON OFF NOCHG)
      return true if valid.include?(val.upcase)
      msg = "Invalid value for #{field}.\n"
      msg += "It should be one of: #{valid.join(', ')}\n"
      msg += "You gave: #{val}\n"
      raise(DNSOMatic::Error, msg)
    end

    def self.url(field, val)
      $stderr.puts "Validating #{field} with #{val} using Validators.url"
      return true if val.match('http.//.*')
      msg = "Invalid value for #{field}.\n"
      msg += "It should be on http(s)-style URL.\n"
      msg += "You gave: #{val}\n"
      raise(DNSOMatic::Error, msg)
    end
  end
end
