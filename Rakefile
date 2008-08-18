require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'
require 'rake/clean'

CLEAN.include("pkg")

spec = Gem::Specification.new do |s|
  s.name		= "dnsomatic"
  s.version		= %x{./dnsomatic --version}
  s.author		= "Ben Walton"
  s.email		= "bdwalton@gmail.com"
  s.homepage		= "http://rubyforge.org/projects/dnsomatic"
  s.rubyforge_project	= "http://rubyforge.org/projects/dnsomatic"
  s.platform		= Gem::Platform::RUBY
  s.summary    		= "A DNS-O-Matic Update Client"
  s.files		= FileList["{bin,lib,tests}/**/*"].exclude("rdoc").to_a
  s.require_path	= "lib"
  s.has_rdoc		= false
  #s.extra_rdoc_files  = ['README']
end

task :default => [:package]

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

