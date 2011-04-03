require 'opt_simple'
require 'test/unit' 
require 'test_unit_extensions'

class TestHelpStatement < Test::Unit::TestCase

  must "add default info to help string" do 
    defaults = {
      :a => 1000
    }
    os = OptSimple.new(defaults)
    os.add_parameter(OptSimple::Option.new '-a' )
    
    assert os.to_s =~/default.*#{defaults['a']}/
  end

  must "order help according to specification order" do 
    os = OptSimple.new({},['-h'])
    os.add_parameter(OptSimple::Option.new '-a')
    os.add_parameter(OptSimple::Flag.new '-b')
    os.add_parameter(OptSimple::Option.new '-c')
    os.add_parameter(OptSimple::Argument.new '-x')
    os.add_parameter(OptSimple::Argument.new '-y')
    os.add_parameter(OptSimple::Argument.new '-z')

    assert os.to_s.match(Regexp.new("\-x.*\-y.*\-z.*\-a.*\-b.*\-c.*",Regexp::MULTILINE))
  end

  must "allow user defined help statements" do
    my_help = "Totally irrelevant"
    os = OptSimple.new({},['-h'])
    os.add_parameter(OptSimple::Option.new '-a')
    os.add_parameter(OptSimple::Flag.new '-b')
    os.help my_help
    
    assert os.to_s == my_help
  end

  must "provide user specified summary statement in help" do
    os = OptSimple.new({},['-h'])
    os.add_parameter(OptSimple::Option.new '-a')
    os.summary "My summary"
    assert os.to_s.match(Regexp.new("My summary",Regexp::MULTILINE))
  end

  must "add metavars to help statement" do 
    os = OptSimple.new({},['-h'])
    os.add_parameter(OptSimple::Option.new '-a',"some help","THING")
    assert os.to_s.match(Regexp.new("\-a.*THING.*some help",Regexp::MULTILINE))
  end
end
