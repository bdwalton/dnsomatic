require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'
require 'rake/clean'

CLEAN.include("pkg", "doc")

spec = Gem::Specification.new do |s|
  s.name		= "dnsomatic"
  s.version		= %x{./bin/dnsomatic --version}
  s.author		= "Ben Walton"
  s.email		= "bdwalton@gmail.com"
  s.homepage		= "http://rubyforge.org/projects/dnsomatic"
  s.rubyforge_project	= "http://rubyforge.org/projects/dnsomatic"
  s.platform		= Gem::Platform::RUBY
  s.summary    		= "A DNS-O-Matic Update Client"
  s.files		= FileList["{bin,lib,tests}/**/*"]
  s.executables		= ['dnsomatic']
  s.default_executable	= 'dnsomatic'
  s.require_path	= 'lib'
  s.has_rdoc		= true
  s.test_file		= 'tests/all_tests.rb'
end

task :default => [:package]

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

