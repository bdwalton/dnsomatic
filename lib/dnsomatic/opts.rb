require 'optparse'
require 'ostruct'
require 'singleton'

module DNSOMatic
  # A class to handle option parsing for the dnsomatic client.
  # It acts as a singleton and will recreate its internal representation
  # of the options each time parse(ARGS) is called.
  class Opts
    @@opts = OpenStruct.new

    include Singleton

    # No arguments, but sets the internal options to the defaults.
    def initialize
      setdefaults()
    end

    # Parse and array of arguments and set the interal options.  Typically
    # ARGV is passed, but that is not required.  Any array of strings that
    # look like arguments will work (makes testing easier).
    def parse(args)
      setdefaults()
      begin
	opts = OptionParser.new do |o|
	  o.on('-m', '--minimum SEC', 'The minimum time between updates (def: 30m)') do |i|
	    @@opts.minimum = i.to_i
	  end

	  o.on('-M', '--maximum SEC', 'The maximum time between updates (def: 15d)') do |i|
	    @@opts.maximum = i.to_i
	  end
#
	  #making this an option (off by default) means we can operate
	  #completely silently by default.
	  o.on('-a', '--alert', 'Emit an alert if the IP is updated') do |a|
	    @@opts.alert = true
	  end

	  o.on('-n', '--name NAME', 'Only update host stanza NAME') do |n|
	    @@opts.name = n
	  end

	  o.on('-d', '--display-config', 'Display the configuration and exit') do 
	    @@opts.showcf = true
	  end

	  o.on('-c', '--config FILE', 'Use an alternate config file') do |f|
	    @@opts.cf = f
	  end

	  o.on('-f', '--force', 'Force an update, even if IP is unchanged') do
	    @@opts.force = true
	  end

	  o.on('-p', '--print', 'Output the update URLs.  No action taken') do
	    @@opts.print = true
	  end

	  o.on('-v', '--verbose', 'Display runtime messages') do
	    @@opts.verbose = true
	  end

	  o.on('-V', '--version', 'Display version and exit') do
	    DNSOMatic::Logger.warn(DNSOMatic::VERSION)
	    exit
	  end

	  o.on('-x', '--debug', 'Output additional info in error situations') do
	    @@opts.debug = true
	  end

	  o.on('-h', '--help', 'Display this help text') do
	    DNSOMatic::Logger.warn(o)
	    exit
	  end
	end
	opts.parse!(args)

	if args.size > 0
	  raise(DNSOMatic::Error, "Extra arguments given: #{args.join(', ')}")
	end

      rescue OptionParser::ParseError => e
	msg = "Extra/Unknown arguments used:\n"
	msg += "\t#{e.message}\n"
	msg += "Remaining args: #{args.join(', ')}\n" if args.size > 0
	raise(DNSOMatic::Error, msg)
      end
    end

    # This is a simple wrapper that passes method calls to our internal option
    # store (an openstruct) so that a client can call opts.alert and get the
    # value from the @@opts.alert variable.
    def method_missing(meth, *args)
      @@opts.send(meth)
    end

    private
    # A quick way to set all of our preferred defaults
    def setdefaults
      @@opts.name = nil
      @@opts.cf = nil
      @@opts.showcf = false
      @@opts.force = false
      @@opts.print = false
      @@opts.verbose = false
      @@opts.minimum = 1800 #30 minutes
      @@opts.maximum = 1296000	#15 days
      @@opts.debug = false
      @@opts.alert = false
    end

  end
end
