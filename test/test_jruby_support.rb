class TestJRubySupport < MTest::Unit::TestCase

  def test_resolve_jruby_home
    real_jruby_home = ENV['JRUBY_HOME']
    js = JRubySupport.new("jruby")
    assert_equal real_jruby_home, js.jruby_home

    ENV['JRUBY_HOME'] = nil
    js = JRubySupport.new("jruby")
    assert_equal real_jruby_home, js.jruby_home

    js = JRubySupport.new("#{real_jruby_home}/bin/jruby")
    assert_equal real_jruby_home, js.jruby_home

    ENV['JRUBY_HOME'] = "/opt/jruby"
    assert_raise RuntimeError do
      JRubySupport.new("jruby")
    end
  end
end

MTest::Unit.new.run
