#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'stringio'

require 'dnsomatic'

class TestConfig < Test::Unit::TestCase
  def setup
    $cfd = File.join(Dir.pwd, 'confs')
  end

  def test_non_existent_conf_raises_exception
    conf = File.join($cfd, 'bad_conf_file_name.cf')
    assert_raises(DNSOMatic::Error) { DNSOMatic::Config.new(conf) }
  end

  def test_empty_conf_raises_exception
    conf = File.join($cfd, 'empty_conf.cf')
    assert_raises(DNSOMatic::Error) { DNSOMatic::Config.new(conf) }
  end

  def test_no_exception_raised_for_basic_conf
    conf = File.join($cfd, 'working_only_defs.cf')
    assert_nothing_raised { DNSOMatic::Config.new(conf) }
  end

  def test_no_exception_raised_for_conf_with_multi_stanzas
    conf = File.join($cfd, '3_good_stanzas.cf')
    assert_nothing_raised { DNSOMatic::Config.new(conf) }
  end

  def teardown
  end
end
