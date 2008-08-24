#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestIPStatus < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $opts.parse(%w(-m 0))
    $local = 'http://benandwen.net/~bwalton/ip_lookup.php'
    $local_ip = %x{wget -q -O - http://benandwen.net/~bwalton/ip_lookup.php}
    $random = 'http://benandwen.net/~bwalton/ip_rand.php'
    $non_lookup = 'http://benandwen.net/~bwalton/non_ip_lookup.txt'
  end

  def test_returns_right_ip
    stat = DNSOMatic::IPStatus.new($local)
    assert_equal($local_ip, stat.ip)
  end

  def test_returns_right_status
    stat1 = DNSOMatic::IPStatus.new($local)
    assert_equal(true, stat1.changed?)
    stat1.update
    assert_equal(false, stat1.changed?)

    stat2 = DNSOMatic::IPStatus.new($random)
    assert_equal(true, stat2.changed?)
    puts stat2.ip
    stat2.update
    puts stat2.ip
    assert_equal(true, stat2.changed?)
  end

  def test_raise_on_bad_args
    assert_raise(DNSOMatic::Error) { DNSOMatic::IPStatus.new($non_lookup) }
  end
end
