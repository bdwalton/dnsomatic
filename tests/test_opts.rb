#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'ostruct'

require 'dnsomatic'

class TestOpts < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
  end

  def test_set_verbose
    $opts.parse(%w(-v))
    assert($opts.verbose)
    $opts.parse(%w(--verbose))
    assert($opts.verbose)
  end

  def test_set_minimum
    $opts.parse(%w(-m 10))
    assert_equal(10, $opts.minimum)
    $opts.parse(%w(--minimum 15))
    assert_equal(15, $opts.minimum)
  end

  def test_set_maximum
    $opts.parse(%w(-M 10))
    assert_equal(10, $opts.maximum)
    $opts.parse(%w(--maximum 15))
    assert_equal(15, $opts.maximum)
  end

  def test_set_alert
    $opts.parse(%w(-a))
    assert($opts.alert)
    $opts.parse(%w(--alert))
    assert($opts.alert)
  end

  def test_set_name
    $opts.parse(%w(-n testcase))
    assert_equal('testcase', $opts.name)
    $opts.parse(%w(--name testcase2))
    assert_equal('testcase2', $opts.name)
  end

  def test_set_display_config
    $opts.parse(%w(-d))
    assert($opts.showcf)
    $opts.parse(%w(--display-config))
    assert($opts.showcf)
  end

  def test_set_config_file
    $opts.parse(%w(-c /tmp/dnsomatic))
    assert_equal('/tmp/dnsomatic', $opts.cf)
    $opts.parse(%w(--config /tmp/dnsomatic2))
    assert_equal('/tmp/dnsomatic2', $opts.cf)
  end

  def test_set_force
    $opts.parse(%w(-f))
    assert($opts.force)
    $opts.parse(%w(--force))
    assert($opts.force)
  end

  def test_extra_opts_raise_exception
    assert_raise(DNSOMatic::Error) { $opts.parse(%w(--badoption)) }
  end

  def test_extra_args_raise_exception
    assert_raise(DNSOMatic::Error) { $opts.parse(%w(somearg)) }
  end
end
