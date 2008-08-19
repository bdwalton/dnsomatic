#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestIPLookup < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $fp = File.join('/tmp', 'dnsomatic.testcache-' + Process.pid.to_s)
    $iplookup = DNSOMatic::IPLookup.instance
    $iplookup.setcachefile($fp)
    $iplookup.persist = false
    $local = 'http://benandwen.net/~bwalton/ip_lookup.php'
    $local_ip = '192.168.0.15'
    $random = 'http://benandwen.net/~bwalton/ip_rand.php'
  end

  def test_cache_works
    stat = $iplookup.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::CHANGED, stat.changed?)
    assert_equal($local_ip, stat.ip)
    stat = $iplookup.ip_for($local)
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
  end

  def test_different_source_returns_new_val
    stat = $iplookup.ip_for($random)
    assert_equal(DNSOMatic::IPStatus::CHANGED, stat.changed?)
  end

  def test_known_ip_change_still_prefers_cache
    stat = $iplookup.ip_for($random)
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
  end

  def test_expiration_with_known_change
    stat = $iplookup.ip_for($random)
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
    $opts.parse(%w(-i 2)) #change expiration to 2s.
    sleep(3)  #make sure we pass the expiration time we just set.
    stat = $iplookup.ip_for($random)
    assert_equal(DNSOMatic::IPStatus::CHANGED, stat.changed?)
  end

  def teardown
    File.delete($fp) if File.exists?($fp)
  end
end
