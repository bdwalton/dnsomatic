#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestIPFetchCache < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $fn = 'testcase.dnsomatic'
    $fp = File.join('/tmp', $fn)
    $ipcache = DNSOMatic::IPFetchCache.instance
    $local = 'http://localhost/~bwalton/http.php'
    $remote = 'http://www.whatismyip.org'
  end

  def test_cache_works
    stat = $ipcache.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::CHANGED, stat.changed?)
    assert_equal('127.0.0.1', stat.ip)
    stat = $ipcache.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
  end

end
