# these are more for unique names than anything else
module DNSOMatic
  class StdErr < StandardError; end
  class ConfErr < DNSOMatic::StdErr;  end
  class UpdErr < DNSOMatic::StdErr;  end
  class HttpErr < DNSOMatic::StdErr; end
end
