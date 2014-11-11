require 'rake/testtask'
#require 'rake/rdoctask'
require 'rdoc/task'

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

task :upload_docs => [:rdoc] do
 sh %(scp -r html/* e_stryker@opt-simple.rubyforge.org:/var/www/gforge-projects/opt-simple)
end

task :release => [:rdoc] do 
  sh %(gem build opt-simple.gemspec)
  sh %(git push  gitosis@rubyforge.org:opt-simple.git master)
  
  # god I love ruby:
  newest_gem = Dir["opt-simple-*.gem"].sort {|a,b| File.mtime(b) <=> File.mtime(a)}.first
  sh "gem1.9.1 push #{newest_gem}"
end
