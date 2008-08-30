#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'stringio'

require 'dnsomatic'

class TestConfig < Test::Unit::TestCase
  def setup
    $cfd = File.join(Dir.pwd, 'confs')
    $orig_home = ENV['HOME']
  end

  def test_no_exception_with_basic_default_conf
    assert_nothing_raised { DNSOMatic::Config.new }
  end

  def test_exception_on_no_config_file
    ENV['HOME'] = '/tmp'
    assert_raises(DNSOMatic::Error) { DNSOMatic::Config.new }
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

  def test_1_def_and_3_alternates_gives_3_updaters
    conf = File.join($cfd, '3_good_stanzas.cf')
    c = DNSOMatic::Config.new(conf)
    assert_equal(3, c.updaters.length)
  end

  def test_3_stanzas_no_def_no_u_p_raises
    conf = File.join($cfd, '3_good_stanzas_no_def.cf')
    assert_raises(DNSOMatic::Error) { DNSOMatic::Config.new(conf) }
  end

  def test_no_defs_no_u_p_raises
    conf = File.join($cfd, '1_stanza_no_defs_no_u_p.cf')
    assert_raises(DNSOMatic::Error) { c = DNSOMatic::Config.new(conf); puts c.merged_config }
  end

  def teardown
    ENV['HOME'] = $orig_home
  end
end
