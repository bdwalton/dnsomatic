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
    assert_equal(DNSOMatic::IPStatus::UNCHANGED, stat.changed?)
  end
end
