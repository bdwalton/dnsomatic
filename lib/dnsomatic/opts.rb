require 'optparse'
require 'ostruct'
require 'singleton'

module DNSOMatic
  class Opts
    @@opts = OpenStruct.new

    include Singleton

    def initialize
      @@opts.name = nil
      @@opts.cf = nil
      @@opts.showcf = false
      @@opts.force = false
      @@opts.print = false
      @@opts.verbose = false
      @@opts.interval = 1800
    end

    def parse(args)
      begin
	opts = OptionParser.new do |o|
	  o.on('-i', '--interval SECONDS', 'Override the default (1800s) minimum interval between updates.') do |i|
	    @@opts.intervalue = i.to_i
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

	  o.on('-f', '--force', 'Force update, even if no IP change detected.') do
	    @@opts.force = true
	  end

	  o.on('-p', '--print', 'Output the URLs that would be used for the updates, but take not action.') do
	    @@opts.print = true
	  end

	  o.on('-v', '--verbose', 'Display runtime messages.') do
	    @@opts.verbose = true
	  end

	  o.on('-h', '--help', 'Display this help text') { puts o; exit; }
	end
	opts.parse!(args)
      rescue OptionParser::ParseError => e
	$stderr.puts "Invalid arguments used: #{e.message}"
	exit 1
      end
    end

    def method_missing(meth, *args)
      @@opts.send(meth)
    end
  end
end
