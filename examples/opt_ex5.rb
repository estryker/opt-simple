#!/usr/bin/env ruby1.9.1

# ./opt_ex2.rb -i foo.bar doit -whatever file1 file2 file3 -- -stuff

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

defaults = {
  "max" => 10
}

options = OptSimple.new(defaults).parse_opts! do 
  banner "USAGE: #{$0}"
  summary "Show how to set a banner and summary."

  argument "-i","inFile" 
  option %w[-m -max --maximum-value],"Maximum val" do |arg|
    set_opt arg.to_i
  end
end

puts "Options"
puts options
