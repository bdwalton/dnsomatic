module DNSOMatic
  # A simple class to provide consistent logging throughout the various other
  # classes.  All methods are class methods, so no instance is required.
  class Logger
    @@opts = Opts.instance
    # Output a message to stdout if the user specified the verbose command
    # line option.
    def self.log(msg)
      $stdout.puts msg if @@opts.verbose
    end

    # Output a message to stderr regardless of verbose command line option.
    def self.warn(msg)
      $stderr.puts msg
    end
  
    # Output a message to stdout if either verbose or alert was specified.
    def self.alert(msg)
      $stdout.puts msg if @@opts.verbose or @@opts.alert
    end
  end
end
