=begin rdoc

= OptSimple provides a very simple interface to command line parsing. 

There are three methods to define command line parameters:

 flag - a command line switch with no arguments following (although you can still use flag
 as a synonym for option. But default behavior is to expect no args.)
 
 option - an optional command line parameter with one or more arguments
 
 argument - a mandatory command line parameter with one or more arguments

Inside the blocks in flag, option, and argument a shortcut function called 'set_opt'
can be used to set an option that will be returned in the options hash.

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
    @longest_switch_len = 0 
    @options = defaults.dup # not sure if I have to dup this
    @positional_arguments = []
    @args = args
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

  # Parse the options, destructively pulling them out of the args array as it goes.
  # If no block is given, then a default parser with no error checking will be run. 
  def parse_opts!(&block)
    
    if block_given?
      # call the block to register all the parameters and
      # their corresponding code blocks
      # We use instance_exec so that the API is cleaner. 
      begin
	instance_exec(@options,@positional_arguments,&block)
      ensure
	# we are ensuring that the options that occur before any break statement
	# actually get parsed. 
	
	# add the help option at the end
	flag %w[-h --help] ,"(for this help message)"
	
	# first look for a call for help
	unless (%w[-h --help] & @args).empty?
	  $stdout.puts self.to_s
	  exit(0)
	end
	
	mandatory_check = mandatory_opts.map {|m| m.switches}
	
	if(loc = @args.index('--'))
	  #remove the '--', but don't include it w/ positional arguments
	  @positional_arguments += @args.slice!(loc..-1)[1..-1] 
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
	  mandatory_check.delete(parm.switches)
	  intersection = @args & parm.switches
	  unless intersection.empty?
	 
	    arg_locations =  []
	    @args.each_with_index {|arg,i| arg_locations << i if intersection.include?(arg) }

	    # we want to process the args in order to provide predictable behavior
	    # in the case of switch duplication. 
	    # We do it in reverse so that the slicing removes pieces from the end so we
	    # don't disrupt the other locations. 
	    chunks = []
	    arg_locations.sort.reverse.each do |loc|  
	      # if we want the first one to win
	      #chunks.push @args.slice!(loc .. loc + parm.block.arity)[1..-1]
	      # if we want the last one to win:
	      chunks.unshift @args.slice!(loc .. loc + parm.block.arity)[1..-1]
	    end

	    chunks.each do | pieces |
	      if pieces.length < parm.block.arity or
		  pieces.any? {|p| p.start_with?('-')}
		raise OptSimple::MissingArgument.new "Not enough args following #{intersection}",self 
	      end
	      
	      begin
		parm.instance_exec(*pieces,&parm.block)
	      rescue OptSimple::Error => e
		raise OptSimple::Error.new e.message,self
	      end
	    end
	    
	    @options.merge!(parm.param_options)
	  end
	end
	
	unless mandatory_check.empty?
	  raise MissingArgument.new "Must set the following parameters: #{mandatory_check.map {|a| a.join(' OR ')}.join(', ')}",self
	end

	extra_switches = @args.find_all {|a| a.start_with?('-') }
	raise OptSimple::InvalidOption.new "Unknown options: #{extra_switches.join(' ')}",self unless extra_switches.empty?
	
	@positional_arguments += @args.slice!(0..-1)
      end
    else
      #parse the @args array by looking for switches/args by regex
      default_arg_parser
    end	
    return [@options,@positional_arguments]
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
	@positional_args += @args[i+1 .. -1]
	break
      elsif arg =~ /^-+(.*)/
	# assume flags are boolean
	@options[$1] = true
	flag = $1
      elsif flag
	# unless followed by an arg
	@options[flag] = arg
	flag = nil
      else
	@positional_args << arg
      end
    end
    @args.slice!(0..-1)
  end

  # Registers an optional parameter, usually with nothing following it. 
  # although if the block has arity > 0, we'll be happy to handle 
  # it as such. 
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
  # and the values set to true when  seen in the args array
  def flag(switches,help="",&block)
    add_parameter(Flag.new(switches,help,&block))
  end

  # Registers an optional parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
  # and the values set to the arg following the switch in the args array.
  def option(switches,help="",metavar="ARG",&block)
    add_parameter(Option.new(switches,help,metavar,&block))
  end

  # Registers a mandatory parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
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
	help_str << parm.help_str(@longest_switch_len) << "\n"
      end 
      help_str << "\n" unless mandatory_opts.empty?
      
      help_str << "  OPTIONS:\n" unless  optional_opts.empty?
      optional_opts.each do | parm |
	help_str << parm.help_str(@longest_switch_len)
	
	# check to see if we have any defaults set to help in the help doc
	intersection = @options.keys & parm.names
	if intersection.empty?
	  help_str << "\n\n"
	else
	  help_str << " (default is #{@options[intersection.first]})\n\n"
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
  # Option and Argument are derived. Provides documentation methods, 
  # an 'error method', and the 'set_opt' utility funciton. 
  class Parameter
    attr_reader :switches,:param_options,:metavar,:block

    # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
    # 'help' provides a description of the parameter
    # and an optional block can do parameter validation/transformation.
    def initialize(switches,help="",&block)
      self.switches = switches
      @help = help
      @block = block
      @param_options = {}
      @names = nil
    end

    # ensures that the switches is an array. Should be an array of Strings
    def switches=(switches)
      @switches = [switches].flatten
    end

    # returns a list of the switches without the leading '-'s
    def names
      @names ||= switches.map {|s| s.sub(/^-+/,'')}
    end

    def switch_len
      @switches.join(', ').length 
    end

    def switch_str
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
    # in the param_options hash. 
    def set_opt val
      names.each {|n| @param_options[n] = val}
    end

    # is it mandatory to see this parameter on the command line?
    def mandatory?; false; end

  end

  # An optional parameter, usually with nothing following it. 
  # although if the block has arity > 0, we'll be happy to handle 
  # it as such. 
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
  # and the values set to true when  seen in the args array  
  class Flag < Parameter
    def initialize(switches,help="",&block)
      super(switches,help,&block)
      if block_given?
	names.each {|n| @param_options[n] = 0 }
      else
	@block = Proc.new { names.each {|n| @param_options[n] = true}}
      end
    end

    def accumulate_opt
      names.each {|n| @param_options[n] += 1}
    end

  end

  # An optional parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
  # and the values set to the arg following the switch in the args array.
  class Option < Parameter
    attr_reader = :metavar
    def initialize(switches,help="",metavar="ARG",&block)
      super(switches,help,&block)
      @metavar = metavar
      if block_given?
	names.each {|n| @param_options[n] = []}
      else
	@block = Proc.new {|arg| names.each {|n| @param_options[n] = arg}}
      end
    end

    def switch_len
      metavar_space = @metavar.empty? ? 0 : @metavar.length + 1 
      super + metavar_space
    end

    def switch_str
      super + " #{@metavar}"
    end

    def accumulate_opt(val)
      names.each {|n| @param_options[n] << val}
    end

  end
  
  # A mandatory parameter, with one or more argument following it.
  # 'switches' can be a String or an Array of Strings, and specifies the switches expected on the CL.
  # 'help' provides a description of the parameter, and 'metavar' will be used in the
  # usage statement.
  # and an optional block can do parameter validation/transformation.
  # If no block is given, then the strings specified (after the 
  # leading '-'s removed) will be used as keys in the options hash 
  # and the values set to the arg following the switch the args array.
  class Argument < Option
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

  # An exception thrown if a mandatory parameter is not
  # used on the command line
  class MissingArgument < Error;end

end
 
