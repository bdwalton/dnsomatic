#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestUpdater < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $fp = File.join('/tmp', 'dnsomatic.testcache-' + Process.pid.to_s)
    $iplookup = DNSOMatic::IPLookup.instance
    $iplookup.setcachefile($fp)
    $iplookup.persist = false
    $local = 'http://benandwen.net/~bwalton/ip_lookup.php'
    $local_ip = %x{wget -q -O - http://benandwen.net/~bwalton/ip_lookup.php}
    $random = 'http://benandwen.net/~bwalton/ip_rand.php'
  end

  def test_config_taken
    
  end
end
