require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'coveralls/rake/task'
Coveralls::RakeTask.new

task "default" => [:ci, 'coveralls:push']

desc "Run all tests for CI"
task "ci" => "spec"

desc "Run all specs"
task "spec" => "spec:all"

namespace "spec" do
  task "all" => ["gaq", "static", "dynamic"]

  desc "Run gaq specs"
  RSpec::Core::RakeTask.new("gaq") do |t|
    t.rspec_opts = "-r ./spec/coveralls_helper"
  end

  desc "Run static specs"
  RSpec::Core::RakeTask.new("static") do |t|
    ENV['RAILS_ENV'] = 'test_static'
    t.pattern = "spec-dummy/spec/**/*_spec.rb"
    t.rspec_opts = "-I spec-dummy/spec --tag ~dynamic"
  end

  desc "Run dynamic specs"
  RSpec::Core::RakeTask.new("dynamic") do |t|
    ENV['RAILS_ENV'] = 'test_dynamic'
    t.pattern = "spec-dummy/spec/**/*_spec.rb"
    t.rspec_opts = "-I spec-dummy/spec --tag ~static"
  end
end
