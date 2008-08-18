#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestIPFetchCache < Test::Unit::TestCase
  def test_returns_right_ip
    ip = '127.0.0.2'
    stat = DNSOMatic::IPStatus.new(ip, DNSOMatic::IPStatus::UNCHANGED)
    assert_equal(ip, stat.ip)
  end

  def test_returns_right_status
    ip = '127.0.0.2'
    stat = DNSOMatic::IPStatus.new(ip, DNSOMatic::IPStatus::UNCHANGED)
    assert_equal(false, stat.changed?)
    stat = DNSOMatic::IPStatus.new(ip, DNSOMatic::IPStatus::CHANGED)
    assert_equal(true, stat.changed?)
  end

  def test_raise_on_bad_args
    ip = '127.0.0.2'
    assert_raise(DNSOMatic::Error) { DNSOMatic::IPStatus.new(ip, ip) }
  end
end
