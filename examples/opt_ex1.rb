#!/usr/bin/env ruby1.9.1

# ./opt_ex1.rb -i infile infile2 infile3

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

defaults = {
'max' => 40
}

options = OptSimple.new(defaults).parse_opts!

puts "Options"
puts options
