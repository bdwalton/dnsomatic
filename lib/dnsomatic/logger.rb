module DNSOMatic
  class Logger
    def self.log(msg)
      $stdout.puts msg if $opts.verbose
    end

    def self.warn(msg)
      $stderr.puts msg
    end

    def self.alert(msg)
      $stdout.puts msg if $opts.verbose or $opts.alert
    end
  end
end
