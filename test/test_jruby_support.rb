class TestJRubySupport < MTest::Unit::TestCase

  def test_jruby_home
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
  ensure
    ENV['JRUBY_HOME'] = real_jruby_home
  end

  def test_jruby_classpath
    js = JRubySupport.new("jruby")
    assert_equal "#{ENV['JRUBY_HOME']}/lib/jruby.jar", js.jruby_classpath
  end

  def test_classpath
    js = JRubySupport.new("jruby")
    assert_equal ["#{ENV['JRUBY_HOME']}/lib/jruby-truffle.jar"], js.classpath
  end

  def test_jruby_opts_env
    ENV['JRUBY_OPTS'] = nil
    js = JRubySupport.new("jruby")
    assert_equal [], js.jruby_opts_env

    ENV['JRUBY_OPTS'] = ""
    js = JRubySupport.new("jruby")
    assert_equal [], js.jruby_opts_env

    ENV['JRUBY_OPTS'] = "--dev"
    js = JRubySupport.new("jruby")
    assert_equal ["--dev"], js.jruby_opts_env

    ENV['JRUBY_OPTS'] = "--dev -J-Xmx1g"
    js = JRubySupport.new("jruby")
    assert_equal ["--dev", "-J-Xmx1g"], js.jruby_opts_env
  ensure
    ENV["JRUBY_OPTS"] = nil
  end

  def test_java_opts
    ENV['JAVA_OPTS'] = nil
    js = JRubySupport.new("jruby")
    assert_equal [], js.java_opts([])

    ENV['JAVA_OPTS'] = ""
    js = JRubySupport.new("jruby")
    assert_equal [], js.java_opts([])

    ENV['JAVA_OPTS'] = "-Dwarbler.port=3000"
    js = JRubySupport.new("jruby")
    assert_equal ["-Dwarbler.port=3000"], js.java_opts([])

    ENV['JAVA_OPTS'] = "-Xmx1g -XX:MaxDirectMemorySize=64m"
    js = JRubySupport.new("jruby")
    assert_equal ["-Xmx1g", "-XX:MaxDirectMemorySize=64m"], js.java_opts([])

    ENV['JAVA_OPTS'] = "-Dwarbler.port=3000"
    js = JRubySupport.new("jruby")
    assert_equal ["-Dwarbler.port=3000", "-XX:MaxDirectMemorySize=64m"], js.java_opts(['-XX:MaxDirectMemorySize=64m'])
  ensure
    ENV["JAVA_OPTS"] = nil
  end
end

MTest::Unit.new.run
