Gem::Specification.new do |spec|
  spec.name = "opt-simple"
  spec.version = "1.0.0"
  spec.summary = "A simple and elegant command line option parser."
  spec.files = Dir['lib/*.rb'] + Dir['test/*.rb'] + 
	  Dir['extensions/*.rb'] + ['README.md','LICENSE.txt']
  spec.has_rdoc = true
  spec.author = "Ethan Stryker"
  spec.email = "e.stryker@gmail.com"
  spec.rubyforge_project = "opt-simple"
  spec.description = <<-END
  Parameter specification, validity checking and argument transformations 
  can be put in one place, default parameters are easily set, and an 
  automatic usage statement is constructed.
  END
  spec.homepage = 'http://opt-simple.rubyforge.org/'
end
