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

  def giveconf(u, p, mx, bmx, w, o, wf = $local, hn = 'all.dnsomatic.com')
    { 'username' => u, 'password' => p, 'mx' => mx, 'backmx' => bmx,
	'wildcard' => w, 'offline' => o , 'webipfetchurl' => wf,
	'hostname' => hn}
  end

  def test_config_taken
    c = giveconf('user', 'mypass', 'NOCHG', 'NOCHG', 'NOCHG', 'NOCHG')
    url = "https://user:mypass@updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip=#{$local_ip}&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG&offline=NOCHG"
    u = DNSOMatic::Updater.new(c)
    assert_equal(url, u.to_s)
  end
end
