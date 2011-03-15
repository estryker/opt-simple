require 'opt_simple'
require 'test/unit' 
require 'test_unit_extensions'

#test the OptSimple::Result class
class TestReturn < Test::Unit::TestCase
  def setup
    @r = OptSimple::Result.new
    @r.add_alias %w[a all]
  end

  must "change all variables that are aliased" do
    @r['a'] = 3
    assert_equal @r['all'],3
  end

  must "set string, symbol in hash notation and respond to method invocation" do
    @r['a'] = 3
    assert_equal @r.a, 3
    assert_equal @r[:a], 3 
    assert_equal @r['a'], 3
    assert_equal @r.all, 3
    assert_equal @r['all'], 3
    assert_equal @r[:all],3
  end

  must "merge with other result objects" do 
    r2 = OptSimple::Result.new
    r2.add_alias %w[b ball]
    r2.b = 4
    @r.a = 7
    r2.merge!(@r)
    assert_equal r2.a,7
    assert_equal r2.all,7
  end

  must "merge with hashes" do
    h = {:a=>1,:z=>26}
    @r.add_vals_from_hash(h)

    assert_equal @r.a,1
    assert_equal @r.z,26
  end

end
