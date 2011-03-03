#!/usr/bin/env ruby1.9.1

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

options,arguments = OptSimple.new.parse_opts! do | opts,tgts |
  argument "-i","inFile" do |arg|
    in_file = arg
    op.error "inFile must exist and be readable" unless(File.readable?(in_file))
  end
  
  option %w[-p --pattern --glob-pattern], "glob pattern"

  flag "-v","Verbose"

  flag "-whatever"

  argument ["--range"], "range: min,max (both >0)" do | arg1,arg2 |
    min = arg1.to_i
    max = arg2.to_i    
    
    error "max must be greater than min" unless max > min
    error "both must be >=0" if min < 0
  end
end

puts "Options"
puts options.inspect

puts "Arguments"
puts arguments.inspect