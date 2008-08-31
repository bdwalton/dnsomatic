#!/usr/bin/ruby -w
$: << '../lib'

require 'test/unit'
require 'stringio'

require 'dnsomatic'

class TestGeneric < Test::Unit::TestCase
  def setup
    $opts = DNSOMatic::Opts.instance
    $orig_out = $stdout
    $stdout = StringIO.new('')
    $opts.parse([])
  end

  def test_version_number_sane
    $opts.parse(%w(-V))
    assert_equal("#{DNSOMatic::VERSION}\n", $stdout.string)
  end

  def teardown
    $stdout.truncate(0)
    $stdout = $orig_out
  end
end
