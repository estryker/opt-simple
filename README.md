## OptSimple provides a very simple interface to command line parsing. 

## Description
Parameter specification, validity checking and argument transformations
can be put in one place, default parameters are easily set, and an automatic
usage statement is constructed.

There are three methods to define command line parameters:

 flag - a command line switch with no arguments following 
 
 option - an optional command line parameter with one or more arguments
 
 argument - a mandatory command line parameter with one or more arguments

Inside the blocks in flag, option, and argument a shortcut function called 'set_opt'
can be used to set an option that will be returned in the Result. The 'accumulate_opt'
method can be used in the option and argument blocks to create a list of values, and in 
the flag block to increment a counter (with verbosity being the classic example). 

The number of arguments are determined by the 'arity' of the block, or a variable
number if the splat operator is used. 

The order in which the parameters are defined dictate their order on the command line.

User defined help banners, summaries or the whole usage statement can be defined. 

## Documentation

See OptSimple for the API specification

## Installation

It is recommended to install OptSimple using RubyGems:

```
 $ sudo gem install opt-simple
```

## Examples

### One example that shows most of the behavior you might use
```ruby
 require 'opt_simple'
 
 defaults = {  
   :glob_pattern => '*',
   :num_results => 42,
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
 
   # this block has arity 2, so it expects two args to follow
   option "--range", "range: min,max (both >0)" do | arg1,arg2 |
     min,max = [arg1.to_i,arg2.to_i]
     set_opt [min,max]
      
     error "max must be greater than min" unless max > min
     error "both must be >=0" if min < 0
   end  

   # this block says that there are a variable number of arguments allowed
   option %w[-t --things],"Some things - variable number allowed","THINGS" do | *args |
     args.each {|a| accumulate_opt a }
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

 puts "Things: #{opts.things.inspect}"
```

```
Which prints out an automatic usage statement:
 Usage: opt_ex.rb [options]
 
   MANDATORY ARGS:
     -i, --infile FILE                           Infile, multiple allowed
 
   OPTIONS:
     -d, --debug                                 debug mode
 
     -m, --cowbell, --morecowbell                I've got a fever, and this is the only prescription.
 
     -n, -num, --num-values VAL                  The answer to everything
 
     -p, --pattern, --glob-pattern PATTERN       glob pattern (default is '*')
 
         --range ARG                             range: min,max (both >0) (default is '[5, 10]')

         -t, --things THINGS                         Some things - variable number allowed 

     -h, --help                                  (for this help message)
```
### A very simple example with no error checking. Use at your own risk!
``` ruby
 require 'opt_simple'
 
 defaults = {
 'max' => 40
 } 
 
 options = OptSimple.new(defaults).parse_opts! 
 
 puts "Options"
 puts options
```
### An example using all default behavior 
```ruby 
 require 'opt_simple'
 
 options = OptSimple.new.parse_opts! do 
   argument "-i","inFile","FILE"
   option %w[-p --pattern --glob-pattern], "glob pattern","PATTERN"
   flag "-v","Verbose"
   flag "-whatever"
 end
 
 puts "Options"
 puts options
```
### An example that shows how to set the banner string, and add a summary.
```ruby
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
```
### An example that shows that you can easily set your defaults in normal Ruby variables and provide your own help.
```ruby 
 require 'opt_simple'
  
 in_file = nil
 min = 0
 max = 10
 pattern = "*"
 
 usage_string = <<-UL
 Usage: $0 [options]
 
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
```  
### An example showing how to register parms in multiple places before parsing the command line
```ruby
 require 'opt_simple'
 
 min = 5
 max = 15
 
 os = OptSimple.new
 
 os.register_opts do 
   argument %w[-i --infile], "Infile, multiple allowed", "FILE" do | arg |
     accumulate_opt arg
   end
 
   option %w[-p --pattern --glob-pattern], "glob pattern","PATTERN"
 end
 
 os.register_opts({num: 7}) do 
   option %w[-n -num --num-values],"Number of val","VAL" do |arg|
     set_opt arg.to_i
   end
 
   option "--range", "range: min,max (both >0) default is #{min},#{max}" do | arg1,arg2 |
     min = arg1.to_i
     max = arg2.to_i    
      
     error "max must be greater than min" unless max > min
     error "both must be >=0" if min < 0
   end
 
   flag %w[-v  --verbose],"Verbosity. the more you set, the more we give" do 
     accumulate_opt
   end
 end
 
 options = os.parse_opts!
 
 puts "Options"
 puts options
``` 
### A totally contrived example showing how to change multiple options within an option specification block

```ruby
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
```
## Questions and/or Comments
  
email [Ethan Stryker](mailto:e.stryker@gmail.com])
 
## License
MIT - see [LICENSE](LICENSE.txt) 
