require 'opt_simple'
require 'test/unit' 
require 'test_unit_extensions'

class TestHelpStatement < Test::Unit::TestCase

  must "disallow name collisions in argument spec" do
    assert_raise(OptSimple::Error) { OptSimple.new.parse_opts! {option %w[-a --awesome]; flag '-awesome' } }
  end

  must "throw parameter missing exception when the argument method is used but the parm isn't specified" do
    os = OptSimple.new({})
    assert_raise(OptSimple::MissingArgument) do
      os.parse_opts! do
	argument '-a'
      end
    end
  end

  must "throw missing parameter usage error when a parameter isn't followed by enough arguments" do
    os = OptSimple.new({},['-a'])
    assert_raise(OptSimple::ParameterUsageError) do
      os.parse_opts! do
	argument '-a' do |arg| 
	  nil
	end
      end
    end
  end
  
  must "raise error when unknown option is given" do 
    os = OptSimple.new({},['-not-specified'])
    assert_raise(OptSimple::InvalidOption) { os.parse_opts! { option %w[-a --awesome]  }  }
  end

  must "handle arguments with equals and commas" do
    os = OptSimple.new({},['-a=2','--foo=4,5'])
    x = nil
    y = nil
    opts= os.parse_opts! do
      option '-a' do |arg| 
	set_opt arg.to_i
      end
      option "--foo" do |a,b|
	x = a.to_i
	y = b.to_i
      end
    end

    assert_equal opts['a'],2
    assert_equal x,4
    assert_equal y,5
  end

  must "accumulate lists of args when asked" do 
    os = OptSimple.new({},%w[-i foo.bar --infile bar.in])
    o = os.parse_opts! do 
      option %w[-i --infile], "Infile, multiple allowed", "FILE" do | arg |
	accumulate_opt arg
      end
    end

    assert_equal o['i'],%w[foo.bar bar.in]
    assert_equal o['infile'],%w[foo.bar bar.in]
  end

  must "accumulate numbers of flags set when asked" do 
    os = OptSimple.new({},%w[-v -v --verbose -v])
    o = os.parse_opts! do 
      flag %w[-v  --verbose],"Verbosity. the more you set, the more we give" do 
	accumulate_opt
      end
    end
    assert_equal o['v'],4
    assert_equal o['verbose'],4
  end

  must "set last arg when duplicated when accumulate opt isn't used" do 
    os = OptSimple.new({},%w[-i foo.bar --infile bar.in -i baz])
    o = os.parse_opts! do 
      option %w[-i --infile], "Infile, multiple allowed", "FILE" do | arg |
	set_opt arg
      end
    end

    assert_equal o['i'],'baz'
    assert_equal o['infile'],'baz'
  end

  must "allow parameters to be registered in multiple spots" do 
    os = OptSimple.new({},%w[-i foo.bar --outfile bar.out])
    os.register_opts do 
      option %w[-i --infile], "Infile", "FILE" do | arg |
	set_opt arg
      end
    end

    os.register_opts do 
      option %w[-o --outfile], "outfile", "FILE" do | arg |
	set_opt arg
      end
    end
    o = os.parse_opts!
    
    assert_equal o['i'],'foo.bar'
    assert_equal o['o'],'bar.out'
  end

  must "set flags to false by default" do
    os = OptSimple.new
    o = os.parse_opts! do 
      flag %w[-v]
    end

    assert_equal o.v, false
  end

  must "add undersore versions to all switch names that have a dash" do 
    os = OptSimple.new({},%w[--some-stuff foo])
    o = os.parse_opts! do 
      option %w[-s --some-stuff]
    end

    assert o.include? 'some_stuff'
    assert_equal o[:some_stuff],"foo"
  end

end

