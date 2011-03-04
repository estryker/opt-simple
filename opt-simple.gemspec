Gem::Specification.new do |spec|
  spec.name = "opt-simple"
  spec.version = "0.7.1"
  spec.summary = "A simple and elegant command line option parser."
  spec.files = Dir['lib/*.rb'] + Dir['test/*.rb'] + 
	  Dir['extensions/*.rb'] + ['README','GPLv2-LICENSE']
  spec.has_rdoc = true
  spec.author = "Ethan Stryker"
  spec.email = "e.stryker@gmail.com"
  spec.rubyforge_project = "opt-simple"
end
