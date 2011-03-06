require 'opt_simple'
require 'test/unit' 
require 'test_unit_extensions'

class TestHelpStatement < Test::Unit::TestCase

  must "disallow name collisions in argument spec" do
    assert_raise(OptSimple::Error) { OptSimple.new.parse_opts! {option %w[-a --awesome]; flag '-awesome' } }
  end

  must "raise error when unknown option is given" do 
    os = OptSimple.new({},['-not-specified'])
    assert_raise(OptSimple::InvalidOption) { os.parse_opts! { option %w[-a --awesome]  }  }
  end

  must "raise error when not enough arguments are given" do
    os = OptSimple.new({},['-a'])
    assert_raise(OptSimple::MissingArgument) do
      os.parse_opts! do
	option '-a' do |arg| 
	  nil
	end
      end
    end
  end

  must "handle arguments with equals and commas" do
    os = OptSimple.new({},['-a=2','--foo=4,5'])
    x = nil
    y = nil
    opts, args = os.parse_opts! do
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
end

