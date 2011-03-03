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

end

