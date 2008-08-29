#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'stringio'

require 'dnsomatic'

class TestLogger < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $stdout = StringIO.new('')
    $opts.parse([])
  end

  def test_nothing_logged_if_not_verbose
    DNSOMatic::Logger.log('nothing logged')
    assert_equal('', $stdout.string)
  end

  def test_log_matches_when_verbose
    $opts.parse(%w(-v))	#enable verbose so that logs are generated
    DNSOMatic::Logger.log('logged')
    assert_equal("logged\n", $stdout.string)
  end

  def test_nothing_alerted_without_verb_or_alert
    DNSOMatic::Logger.alert('nothing logged')
    assert_equal('', $stdout.string)
  end

  def test_alert_with_alert_opt
    $opts.parse(%w(-a))
    DNSOMatic::Logger.alert('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_alert_with_verbose_opt
    $opts.parse(%w(-v))
    DNSOMatic::Logger.alert('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_alert_with_verbose_and_alert_opts
    $opts.parse(%w(-v -a))
    DNSOMatic::Logger.alert('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_warn_without_verbose_or_alert
    DNSOMatic::Logger.warn('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_warn_with_verbose
    $opts.parse(%w(-v))
    DNSOMatic::Logger.warn('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_warn_with_alert
    $opts.parse(%w(-a))
    DNSOMatic::Logger.warn('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def test_warn_with_alert_and_verbose
    $opts.parse(%w(-a -v))
    DNSOMatic::Logger.warn('something logged')
    assert_equal("something logged\n", $stdout.string)
  end

  def teardown
    $stdout.truncate(0)
  end
end
