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
    options,arguments = @os.parse_opts &@block
    assert arguments.include? '-infile4' and arguments.include? 'infile5'
  end

  must "return all positional args in the arguments list" do 
    options,arguments = @os.parse_opts &@block
    assert_equal arguments.sort,%w[infile1 infile2 infile3 -infile4 infile5].sort
  end

  must "empty out ARGV when using parse_opts!" do
    arg_copy = @args.dup
    @os.parse_opts! &@block 
    assert @args.empty?
  end

  must "preserve ARGV when using parse_opts" do
    arg_copy = @args.dup
    @os.parse_opts &@block 

    assert_equal @args.sort,arg_copy.sort
  end

end
