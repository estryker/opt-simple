#!/usr/bin/env ruby1.9.1

# ./opt_ex6.rb -i foo.bar --infile bar.in -v -v --verbose -v 

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

defaults = {
  :num_values => 42,
  :range => [5,10]
}

opts = OptSimple.new(defaults).parse_opts! do 
  argument %w[-i --infile], "Infile, multiple allowed", "FILE" do | arg |
    accumulate_opt arg
  end

  flag %w[-d --debug],"debug mode"

  flag %w[-m --cowbell --morecowbell],"I've got a fever, and this is the only prescription." do 
    accumulate_opt
  end
  
  option %w[-n -num --num-values],"The answer to everything","VAL" do |arg|
    set_opt arg.to_i
  end

  option %w[-p --pattern --glob-pattern], "glob pattern","PATTERN"

  option "--range", "range: min,max (both >0)" do | arg1,arg2 |
    min,max = [arg1.to_i,arg2.to_i]
    set_opt [min,max]
     
    error "max must be greater than min" unless max > min
    error "both must be >=0" if min < 0
  end
end

puts "Options"
puts opts

# you can use method syntax to access the options
puts "Infile list: #{opts.infile}"

# Flags are set to false by default
puts "Debug" if opts.debug

# If accumulate_opt is used, flags still default to false, but
# will be integers if set on the CL
puts "Cowbell: #{opts['cowbell']}"

# Dashes will be replaced by underscores so that method syntax works nicely 
puts "N: #{opts.num_values}"
puts "N: #{opts['num-values']}"

# You can check to see if Options were set
# and you can use hash syntax to access the options as strings or symbols
puts "Pattern: #{opts[:p]}" if opts.include?(:p)

# Here, range was set to an Array. 
puts "Range: #{opts.range.first} #{opts.range.last}"
