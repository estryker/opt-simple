#!/usr/bin/env ruby1.9.1

# ./opt_ex2.rb -i foo.bar doit -whatever file1 file2 file3 -- -stuff

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

options = OptSimple.new.parse_opts! do 
  argument "-i","inFile","FILE"
  option %w[-p --pattern --glob-pattern], "glob pattern","PATTERN"
  flag "-v","Verbose"
  flag "-whatever"
end

puts "Options"
puts options
