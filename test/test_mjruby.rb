class TestMJruby < MTest::Unit::TestCase

  def test_jruby_opts_env
    ENV['JRUBY_OPTS'] = "--dev -J-cp foo.jar    --2.0  -J-Xms1g"
    assert_equal jruby_opts_env, ["--dev", "-J-cp", "foo.jar", "--2.0", "-J-Xms1g"]
  end
end

MTest::Unit.new.run
