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

  def test_fresh_load_returns_new
    ip, status = $ipcache.ip_for($local)
    assert_equal('changed', status)
    assert_equal('127.0.0.1', ip)
  end

  def test_second_load_returns_unchanged
    ip, status = $ipcache.ip_for($local)
    assert_equal('changed', status)
    assert_equal('127.0.0.1', ip)
    ip, status = $ipcache.ip_for($local)
    assert_equal('unchanged', status)
    assert_equal('127.0.0.1', ip)
  end

  def teardown
    File.exists?($fp) && File.delete($fp)
  end

end
