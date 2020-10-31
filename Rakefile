#!/usr/bin/env rake

require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
require "rubocop/rake_task"
require "rake/testtask"

task default: %w[lint test]

desc "Run regression tests"
Rake::TestTask.new do |test|
	test.libs << "lib" << "test"
	test.pattern = "test/*_test.rb"
end

desc "Lint source code using RuboCop"
RuboCop::RakeTask.new(:lint) do |task|
	task.patterns = ["bin/*", "lib/**/*.rb", "test/*.rb"]
end

gemspec = Gem::Specification.load("github-mandoc.gemspec")
