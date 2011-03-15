#!/usr/bin/env ruby1.9.1

# ./opt_ex2.rb -i foo.bar doit -whatever file1 file2 file3 -- -stuff

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

defaults = {
  "max" => 10
}

options = OptSimple.new(defaults).parse_opts! do 
  argument "-i","inFile","FILE"
  option %w[-m -max --maximum-value],"Maximum val","MAXVAL" do |arg|
    set_opt arg.to_i
  end
end

puts "Options"
puts options
