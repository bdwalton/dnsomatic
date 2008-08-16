require 'open-uri'

module DNSOMatic
  class HTTPAgent
    @@AGENT = "Ruby_DNS-o-Matic/#{DNSOMatic::VERSION}"
    def self.fetch (url)
      uri = URI.parse(url)

      begin
        res = if uri.user and uri.password
		open(url,
		       'User-Agent' => @@AGENT,
		       :http_basic_authentication => [uri.user, uri.password])
	      else
		open(url, 'User-Agent' => @@AGENT)
	      end
	res.read
      rescue OpenURI::HTTPError, SocketError => e
	msg = "Error communicating with #{uri.host}\n"
	msg += "Message was: #{e.message}\n"
	msg += "Full URL being requested: #{uri}"
	raise(DNSOMatic::HttpErr, msg)
      end
    end
  end
end
