#!/usr/bin/env ruby

# A totally contrived example showing how to change multiple options within an option specification block

$LOAD_PATH.unshift File.dirname($PROGRAM_NAME)
$LOAD_PATH.unshift File.dirname($PROGRAM_NAME) + '/../lib/'

require 'opt_simple'

allowed_odds = [1,3,5,7]
allowed_evens = [2,4,6]
defaults = {
  :even_val => allowed_evens.first,
  :odd_val => allowed_odds.first
}

# Note that b/c we define option [--odd] and [--evens] _after_ the max-out flag, 
# they will override the max-out setting. 
opts = OptSimple.new(defaults).parse_opts! do | opt_obj |
  flag %w[-m --max-out], "Maximize evens and odds." do 
    opt_obj.odd_val = allowed_odds.last
    opt_obj.even_val = allowed_evens.last
  end
  
  option "--odd-val","Odd val in #{allowed_odds.inspect}","VAL" do | arg |
    val = arg.to_i
    error "Odd val must be in #{allowed_odds.inspect}" unless allowed_odds.include? val
    set_opt val
  end

  option "--even-val","Even val #{allowed_evens.inspect}","VAL" do | arg |
    val = arg.to_i
    error "Even val must be in #{allowed_evens.inspect}" unless allowed_evens.include? val
    set_opt val
  end
end

puts "Options"
puts opts
