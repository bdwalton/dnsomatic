require 'yaml'

module DNSOMatic
  class YAMLWrap
    def self.read(file)
      begin
	yaml = YAML::load(File.open(file))
      rescue Exception => e
	msg = "An exception occurred while reading a yaml file: #{file}\n"
	msg += "The error message is: #{e.message}"
	raise(DNSOMatic::ConfErr, msg)
      end
    end

    def self.write(file, data)
      begin
	File.open(file, 'w') do |f|
	  f.puts data.to_yaml
	end
      rescue Exception => e
      end
    end
  end
end
