#!/usr/bin/env rake
# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec
