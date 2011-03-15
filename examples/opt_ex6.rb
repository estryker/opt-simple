#!/usr/bin/env ruby1.9.1

# ./opt_ex6.rb -i foo.bar --infile bar.in -v -v --verbose -v 

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

verbosity = 0

options = OptSimple.new.parse_opts! do 
  option %w[-i --infile], "Infile, multiple allowed", "INFILE" do | arg |
    accumulate_opt arg
  end

  flag %w[-v  --verbose],"Verbosity. the more you set, the more we give" do 
    verbosity += 1
  end

  flag %w[-m --more-cow-bell], "I've got a fever" do 
    accumulate_opt
  end

end

puts "Options"
puts options

puts "Verbosity"
puts verbosity

