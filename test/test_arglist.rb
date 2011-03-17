require 'opt_simple'
require 'test/unit' 
require 'test_unit_extensions'

class ArglistTest < Test::Unit::TestCase
  def setup
    @args = %w[infile1 -v infile2 -o out.txt infile3 -- -infile4 infile5]
    @os = OptSimple.new({},@args)
    @block = Proc.new {
      flag '-v'
      argument '-o'
    }
  end

  must "put all args after the dash dash in the pos argument list" do
    options = @os.parse_opts &@block
    assert options.positional_args.include? '-infile4' and options.positional_args.include? 'infile5'
  end

  must "return all positional args in the arguments list" do 
    options = @os.parse_opts &@block
    assert_equal options.positional_args.sort,%w[infile1 infile2 infile3 -infile4 infile5].sort
  end

  must "only keep positional args in ARGV when using parse_opts!" do
    @os.parse_opts! &@block 
    assert_equal @args,%w[infile1 infile2 infile3 -infile4 infile5]
  end

  must "have ARGV and opts.positional_args identical when calling parse_opts!" do 
    opts = @os.parse_opts! &@block 
    assert_equal @args,opts.positional_args
  end

  must "preserve ARGV when using parse_opts" do
    arg_copy = @args.dup
    @os.parse_opts &@block 

    assert_equal @args.sort,arg_copy.sort
  end

end
