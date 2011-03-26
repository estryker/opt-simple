=begin rdoc

= OptSimple provides a very simple interface to command line parsing. 

There are three methods to define command line parameters:

 flag - a command line switch with no arguments following. 
 
 option - an optional command line parameter with one or more arguments
 
 argument - a mandatory command line parameter with one or more arguments

Inside the blocks in flag, option, and argument a shortcut function called 'set_opt'
can be used to set an option that will be returned in the Result. The 'accumulate_opt'
method can be used in the option and argument blocks to create a list of values, and in 
the flag block to increment a counter (with verbosity being the classic example). 

The number of arguments are determined by the 'arity' of the block. 

The order in which the parameters are defined dictate their order on the command line.

User defined help banners, summaries or the whole usage statement can be defined. 
=end
class OptSimple
  attr_accessor :args
  attr_reader :mandatory_opts, :optional_opts

  # default keys should should be strings, 
  # args can be any list of strings, but defaults to ARGV
  def initialize(defaults = {},args = ARGV)
    @mandatory_opts = []
    @optional_opts = []
    @parameters = []
    @param_names = {}
    @results = OptSimple::Result.new
    @longest_switch_len = 0 
    @defaults = defaults
    @args = args.to_a # especially for jruby
    @banner = "Usage: #{File.basename($0)} [options]"
    @summary = ""
    @help = ""
  end

  # set the Summary string at the end of the usage statement
  def summary(str)
    @summary = str
  end

  # provide a user defined help string, and override the auto-generated one
  def help(str)
    @help = str
  end
  
  # set the banner to str, overriding the default: "Usage: #{File.basename($0)} [options]"
  def banner(str)
    @banner = str
  end

  # Simply register options without actually parsing them. 
  # This allows registering parms in multiple places in your code.
  def register_opts(&block)
    # call the block to register all the parameters and
    # their corresponding code blocks
    # We use instance_exec so that the API is cleaner. 
    instance_exec(@results,&block) 
  end

  # Parse the options, destructively pulling them out of the args array as it goes.
  # If no block is given, then a default parser with no error checking will be run. 
  def parse_opts!(&block)
    
    if block_given?
      register_opts(&block)
    end

    if @parameters.empty?
      #parse the @args array by looking for switches/args by regex
      default_arg_parser
    else
      # add the help option at the end, but only use -h if it hasn't been used
      # already (cuz we're that nice).
      help_strings = %w[-h --help]
      if(@parameters.find {|p| p.switches.include?('-h')})
	help_strings = %w[--help]
      end
      flag help_strings ,"(for this help message)"

      # go through the  registered parameters, and pull out 
      # the specified parms from @arg

      # first look for a call for help
      unless (help_strings & @args).empty?
	$stdout.puts self.to_s
	exit(0)
      end
      
      mandatory_check = mandatory_opts.map {|m| m.switches}
      
      positional_args = []
      if(loc = @args.index('--'))
	#remove the '--', but don't include it w/ positional arguments
	positional_args = @args.slice!(loc..-1)[1..-1]
      end
      
      # Handle the case where a user specifies --foo=bar, or --foo=bar,baz
      equal_args = @args.find_all {|arg| arg.include?('=') }
      @args.delete_if {|arg| arg.include?('=') }
      equal_args.each do | e |
	switch,list = e.split('=')
	@args << switch
	list.split(',').each {|val| @args << val }
      end
      
      # now actually parse the args, and call all the stored up blocks from the options
      @parameters.each do | parm |
	intersection = @args & parm.switches
	
	# load the defaults for this particular parm no matter what is on the CL
	default_switches = @defaults.keys & parm.names
	if default_switches.length > 1
	  raise OptSimple::Error "Clashes in the defaults for #{parm.switches}"
	elsif default_switches.length == 1
	  # set the default value before we see what is on the CL
	  parm.param_options[default_switches.first] = @defaults[default_switches.first]
	  @results.merge! parm.param_options
	end

	unless intersection.empty?
	  mandatory_check.delete(parm.switches)
	  
	  arg_locations =  []
	  @args.each_with_index {|arg,i| arg_locations << i if intersection.include?(arg) }
	  
	  # we want to process the args in order to provide predictable behavior
	  # in the case of switch duplication. 
	  # We do pull them out in reverse so that the slicing removes pieces from the end 
	  # of @args, so we don't disrupt the other locations, but put them into 'chunks'
	  # backwards to restore their order. 
	  chunks = []
	  arg_locations.sort.reverse.each do |loc|  
	    chunks.unshift @args.slice!(loc .. loc + parm.block.arity)[1..-1]
	  end
	  
	  chunks.each do | pieces |
	    if pieces.length < parm.block.arity or
		pieces.any? {|p| p.start_with?('-')}
	      raise OptSimple::ParameterUsageError.new "Not enough args following #{intersection}",self 
	    end
	    
	    begin
	      parm.instance_exec(*pieces,&parm.block)
	    rescue OptSimple::Error => e
	      raise OptSimple::Error.new e.message,self
	    end
	  end
	  @results.merge! parm.param_options
	end
      end
      
      unless mandatory_check.empty?
	raise MissingArgument.new "Must set the following parameters: #{mandatory_check.map {|a| a.join(' OR ')}.join(', ')}",self
      end
      
      extra_switches = @args.find_all {|a| a.start_with?('-') }
      raise OptSimple::InvalidOption.new "Unknown options: #{extra_switches.join(' ')}",self unless extra_switches.empty?

      @results.positional_args = @args + positional_args
      # put back the positional args that were taken off after the '--'
      @args.concat(positional_args)
    end

    return @results
  end

  # Parse the options in a non-destructive way to the args array passed in.
  # If no block is given, then a default parser with no error checking will be run. 
  def parse_opts(&block)
    @original_args = @args # do I really need these around?
    @args = @args.dup
    parse_opts! &block
  end

  # You do not want to call this function. 
  # This provides a default behavior for all switches on the command line if no
  # block is given to parse_opts
  def default_arg_parser 
    flag = nil
    @args.each_with_index do |arg,loc|
      if arg == '--'
	# end of flag marker
	@results.positional_args += @args[loc+1 .. -1]
	break
      elsif arg =~ /^-+(.*)/
	# assume flags are boolean
	@results[$1] = true
	flag = $1
      elsif flag
	# unless followed by an arg
	@results[flag] = arg
	flag = nil
      else
	@results.positional_args << arg
      end
    end
    @args.delete_if {|a| not @results.positional_args.include?(a)}
  end

  # Registers an optional parameter, usually with nothing following it.
  # If  not set on the CL, it will be false in the Result. 
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to true when  seen on the CL
  def flag(switches,help="",&block)
    parm = Flag.new(switches,help,&block)
    add_parameter(parm)

    # use the first name b/c they are all aliased anyways.
    @defaults[parm.names.first] = false
  end

  # Registers an optional parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to the arg following the switch on the CL.
  def option(switches,help="",metavar="ARG",&block)
    add_parameter(Option.new(switches,help,metavar,&block))
  end

  # Registers a mandatory parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to the arg following the switch the args array.
  def argument(switches,help="",metavar="ARG",&block)
    add_parameter(Argument.new(switches,help,metavar,&block))
  end

  # A shortcut for raising an OptSimple::Error exception
  def error(string=nil)
    raise OptSimple::Error.new string
  end

  # returns the automatic usage statement
  def to_s
    if @help.empty?
      help_str = ""
      
      help_str << "  MANDATORY ARGS:\n" unless mandatory_opts.empty?
      mandatory_opts.each do | parm |
	help_str << parm.help_str(@longest_switch_len) << "\n\n"
      end 
      
      help_str << "  OPTIONS:\n" unless  optional_opts.empty?
      optional_opts.each do | parm |
	help_str << parm.help_str(@longest_switch_len)
	
	# check to see if we have any defaults for options and args only
	# to add to the help doc
	intersection = []

	intersection = @defaults.keys & parm.names unless parm.class == Flag
	if intersection.empty?
	  help_str << "\n\n"
	else
	  help_str << " (default is #{@defaults[intersection.first]})\n\n"
	end
      end
      help_str << "  SUMMARY:\n\n    #{@summary}\n\n" unless @summary.empty?
      
      @help = @banner + "\n\n" + help_str 
    end
    @help
  end

  # You probably don't want to call this method. 
  # A lower level function that adds a Flag, Option, or Argument,
  def add_parameter(parm)
    
    @longest_switch_len = parm.switch_len if parm.switch_len > @longest_switch_len

    parm.names.each do | n |
      if @param_names.has_key?(n)
	raise OptSimple::Error.new "Command line switch already in use!"
      else
	@param_names[n] = true
      end

    end
    @parameters << parm
    @mandatory_opts << parm if parm.mandatory?
    @optional_opts << parm if not parm.mandatory?
  end

  # The base class for command line parameter objects from which Flag, 
  # Option and Argument are derived. Users will probably only use the 
  # an 'error method' and the 'set_opt' utility funciton. 
  class Parameter
    attr_reader :switches,:param_options,:metavar,:block

    # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
    # 'help' provides a description of the parameter
    # and an optional block can do parameter validation/transformation.
    def initialize(switches,help="",&block)
      self.switches = switches
      @help = help
      @block = block
      @param_options = OptSimple::Result.new
      @param_options.add_alias(self.names)
    end

    # ensures that the switches is an array. Should be an array of Strings
    def switches=(switches)
      @switches = [switches].flatten
    end

    # returns a list of the switches without the leading '-'s
    def names
      names = []
      switches.each do  |s| 
	st = s.sub(/^-+/,'')
	names << st << st.to_sym
      end
      names 
    end

    def switch_len #:nodoc:
      @switches.join(', ').length 
    end

    def switch_str #:nodoc:
      short_parms = @switches.find_all {|st| st.start_with?('-') and st.length == 2 and st[1] != '-'} 
      long_parms = @switches.find_all {|st| st.start_with?('--') or (st.start_with?('-') and st.length > 2)} 
      other_parms = @switches.find_all {|st| not st.start_with?('-')}
      
      sh_str = short_parms.empty? ?  " " * 4 : short_parms.first
      long_str = long_parms.join(', ') + other_parms.join(', ')
      sh_str << ', ' unless sh_str =~/^\s+$/ or long_str.empty?

      sh_str + long_str
    end

    # a single line that will be put in the overall usage string
    def help_str(switch_len)
      "    %-#{switch_len}s"  % self.switch_str + " \t#{@help}"
    end

    # A shortcut for raising an OptSimple::Error exception
    def error(string)
      raise OptSimple::Error.new string
    end

    # A utility function that sets all the names to the specified value
    # in the param_options data structure. 
    def set_opt val
      # all the other values are aliased, so we only need to set the first
      @param_options[names.first] = val
    end

    # is it mandatory to see this parameter on the command line? Returns false unless overidden.  
    def mandatory?; false; end

  end

  # An optional parameter, usually with nothing following it. 
  # If  not set on the CL, it will be false in the Result. 
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to true when seen on the CL  
  class Flag < Parameter
    def initialize(switches,help="",&block)
      super(switches,help,&block)
      if block_given?
	@param_options[names.first] = false
      else
	@block = Proc.new { @param_options[names.first] = true}
      end
    end
    
    # increment the parameter by one every time it is seen on the CL
    def accumulate_opt
      # if this is the first time seen, set it to 1. 
      if @param_options[names.first] == false
	@param_options[names.first] = 1
      else
	@param_options[names.first] += 1
      end
    end

  end

  # An optional parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to the arg following the switch on the CL.
  class Option < Parameter
    attr_reader = :metavar
    def initialize(switches,help="",metavar="ARG",&block)
      super(switches,help,&block)
      @metavar = metavar
      if block_given?
	@param_options[names.first] = []
      else
	@block = Proc.new {|arg| @param_options[names.first] = arg}
      end
    end

    def switch_len #:nodoc:
      metavar_space = @metavar.empty? ? 0 : @metavar.length + 1 
      super + metavar_space
    end

    def switch_str #:nodoc:
      super + " #{@metavar}"
    end

    # append val to the parameter list
    def accumulate_opt(val)
      @param_options[names.first] << val
    end

  end
  
  # A mandatory parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the Result 
  # and the values set to the arg following the switch the args array.
  class Argument < Option
    # returns true in an Argument
    def mandatory?; true; end
  end

  # A general error in the options
  class Error < Exception
    def initialize(string,option_obj=nil)
      super("#{string}\n#{option_obj.to_s}")
      set_backtrace []
    end
  end

  # An exception that is thrown if an unspecified parameter
  # is used on the command line
  class InvalidOption < Error;end

  # An exception thrown  if a mandatory parameter is not
  # used on the command line
  class MissingArgument < Error;end

  # An exception thrown if a parameter isn't followed by enough arguments
  # on the command line
  class ParameterUsageError < Error;end

  # The Results after parsing the CL in a hash-like object with method
  # syntax for getters/setters as well. Each Result that belong to the same 
  # Parameter are aliased to keep consistent
  class Result
    attr_accessor :positional_args
    
    def initialize
      @name_to_aliases = {}
      @inside_hash = {}
      @positional_args = []
    end
    
    # hash notation setter
    def []=(key,value)
      if @name_to_aliases.has_key?(key)
	@inside_hash[@name_to_aliases[key]] = value
      else
	add_alias(key) 
	@inside_hash[[key].flatten] = value
      end
    end
    
    # hash notation getter
    def [](key)
      @inside_hash[@name_to_aliases[key]]
    end
    
    # add a list of items that should be treated as the same key
    def add_alias(list)
      alias_list = [list].flatten
      alias_list.each do | item |
	@name_to_aliases[item] = alias_list
	@name_to_aliases[item.to_s] = alias_list
	@name_to_aliases[item.to_sym] = alias_list
      end
    end
    
    # copy the values from hash into this Result object
    def add_vals_from_hash(hash)
      hash.keys.each { |k| self[k] = hash[k] }
    end
    
    # merge non-destructively, and return the Result
    def merge(other)
      r = Result.new
      r.merge! self
      r.merge! other
    end

    # merge into this Result and return the Result
    def merge!(other)
      other.aliases.each do | a | 
	add_alias(a)
	self[a.first] =  other[a.first]
      end
    end

    # check to see if the 'key' option was set
    def include?(key)
      @inside_hash.include?(@name_to_aliases[key])
    end

    # a list of all the aliases
    def aliases
      @name_to_aliases.values.uniq
    end

    # this allows for method calls for getters/setters
    def method_missing(sym,*args,&block)
      sym_str = sym.to_s
      if @name_to_aliases.has_key?(sym)
	return @inside_hash[@name_to_aliases[sym]]
      elsif sym_str.end_with?('=') and
	  @name_to_aliases.has_key?(sym_str[0..-2])
	@inside_hash[@name_to_aliases[sym_str[0..-2]]] = args.first
      else
	super(sym,*args,&block)
      end
    end

    # a hash looking return string.
    def to_s
      ret = ""
      aliases.each do | a |
	ret << "#{a}=>#{@inside_hash[a]},"
      end
      return "{#{ret[0..-2]}}\n#{@positional_args.inspect}\n"
    end
  end
end
 
