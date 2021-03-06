#!/usr/bin/env ruby1.9.1

# ./opt_ex3.rb -i instance_eval.rb --range 4 6 file1 file2

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'
 
require 'opt_simple'

in_file = nil
min = 0
max = 10
pattern = "*"

usage_string = <<-UL

Usage: #{$0} [options]

   -i, --infile FILE
  [--range (min - default #{min}, max - default #{max})]
  [-p, --pattern, --glob-pattern (default #{pattern})]
  [-v (verbose)]
  [-h, --help (help)]
UL

OptSimple.new.parse_opts! do
  help usage_string
   
  argument %w[-i --infile],"inFile" do |arg|
    in_file = arg
    error "inFile must exist and be readable" unless(File.readable?(in_file))
  end
   
  option ["--range"], "range: min,max (both >0) default is #{min},#{max}" do | arg1,arg2 |
    min = arg1.to_i
    max = arg2.to_i    
     
    error "max must be greater than min" unless max > min
    error "both must be >=0" if min < 0
  end  
 
  option %w[-p --pattern --glob-pattern], "glob pattern, default is #{pattern}" do |arg|
    pattern = arg
  end
 
  flag "-v","Verbose"
 
end
 
puts "in_file #{in_file}"
puts "min #{min}"
puts "max #{max}"
puts "pattern #{pattern}"

puts "ARGV"
puts ARGV


