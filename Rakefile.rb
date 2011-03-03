require 'rake/testtask'
require 'rake/rdoctask'

Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
end

Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README","lib/*.rb")
  rd.options << "--all"
  rd.options << "--inline-source"
end
