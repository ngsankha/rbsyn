require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/unit/*_test.rb"]
end

Rake::TestTask.new(:bench) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.libs << "models"
  t.test_files = FileList["test/benchmark/*_benchmark.rb"]
end

task :default => [] do
  Rake::Task[:test].execute
  Rake::Task[:bench].execute
end
