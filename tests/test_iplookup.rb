#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestIPFetchCache < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $fp = File.join('/tmp', 'dnsomatic.testcache')
    $iplookup = DNSOMatic::IPLookup.instance
    $iplookup.setcachefile($fp)
    $local = 'http://localhost/~bwalton/http.php'
    $remote = 'http://www.whatismyip.org'
  end

  def test_cache_works
    stat = $iplookup.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::CHANGED, stat.changed?)
    assert_equal('127.0.0.1', stat.ip)
    stat = $iplookup.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
  end

  def teardown
    File.delete($fp)
  end
end
