#!/usr/bin/env ruby1.9.1

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

min = 5
max = 10
options = OptSimple.new.parse_opts! do
  argument %w[-i --infile],"input file","FILE" do |arg|
    error "inFile must exist and be readable" unless(File.readable?(arg))
    set_opt arg
  end
  
  option %w[-p --pattern --glob-pattern], "glob pattern"

  flag "-v","Verbose"

  flag "-whatever"

  option ["--range"], "both > 0, defaults are #{min},#{max}","MIN,MAX" do | arg1,arg2 |
    min = arg1.to_i
    max = arg2.to_i    
    
    error "max must be greater than min" unless max > min
    error "both must be >=0" if min < 0
  end
end

puts "Options"
puts options
