require 'optparse'
require 'ostruct'
require 'singleton'

module DNSOMatic
  class Opts
    @@opts = OpenStruct.new

    include Singleton

    def initialize
      setdefaults()
    end

    def parse(args)
      setdefaults()
      begin
	opts = OptionParser.new do |o|
	  o.on('-i', '--interval SECONDS', 'Override the minimum update interval.') do |i|
	    @@opts.interval = i.to_i
	  end
#
	  #making this an option (off by default) means we can operate
	  #completely silently by default.
	  o.on('-a', '--alert', 'Emit an alert if the IP is updated.') do |a|
	    @@opts.alert = true
	  end

	  o.on('-n', '--name NAME', 'Only update host stanza NAME') do |n|
	    @@opts.name = n
	  end

	  o.on('-d', '--display-config', 'Display the configuration and exit.') do 
	    @@opts.showcf = true
	  end

	  o.on('-c', '--config FILE', 'Use an alternate config file.') do |f|
	    @@opts.cf = f
	  end

	  o.on('-f', '--force', 'Force an update, even if IP is unchanged.') do
	    @@opts.force = true
	  end

	  o.on('-p', '--print', 'Output the update URLs.  No action taken.') do
	    @@opts.print = true
	  end

	  o.on('-v', '--verbose', 'Display runtime messages.') do
	    @@opts.verbose = true
	  end

	  o.on('--version', 'Display version and exit.') do
	    $stdout.puts DNSOMatic::VERSION
	    exit 0
	  end

	  o.on('-x', '--debug', 'Output additional info in error situations.') do
	    @@opts.debug = true
	  end

	  o.on('-h', '--help', 'Display this help text') { puts o; exit; }
	end
	opts.parse!(args)

      rescue OptionParser::ParseError => e
	msg = "Extra/Unknown arguments used:\n"
	msg += "\t#{e.message}\n"
	msg += "Remaining args: #{args.join(', ')}" if args.size > 0
	raise(DNSOMatic::Error, msg)
      end
    end

    def method_missing(meth, *args)
      @@opts.send(meth)
    end

    private
    def setdefaults
      @@opts.name = nil
      @@opts.cf = nil
      @@opts.showcf = false
      @@opts.force = false
      @@opts.print = false
      @@opts.verbose = false
      @@opts.interval = 1800
      @@opts.debug = false
      @@opts.alert = false
    end

  end
end
