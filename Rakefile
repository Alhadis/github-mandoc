#!/usr/bin/env rake

require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |test|
	test.libs << "lib" << "test"
	test.pattern = "test/*_test.rb"
end

gemspec = Gem::Specification.load("github-mandoc.gemspec")

task :default => :test
