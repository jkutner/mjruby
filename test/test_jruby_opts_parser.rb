class TestMjruby < MTest::Unit::TestCase

  def test_parse
    parser = JRubyOptsParser.parse(["-J-Xmx1g"])
    assert_equal "-Xmx1g", parser.java_mem
    assert_equal [], parser.java_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse(["-J-Xms1g"])
    assert_equal "-Xms1g", parser.java_mem_min
    assert_equal [], parser.java_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse(["-Xcext.enabled=true"])
    assert_equal ["-Xcext.enabled=true"], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse(["--manage"])
    assert_equal [
      "-Dcom.sun.management.jmxremote",
      "-Djruby.management.enabled=true"], parser.java_opts
      assert parser.valid?

    parser = JRubyOptsParser.parse(["--headless"])
    assert_equal ["-Djava.awt.headless=true"], parser.java_opts
    assert parser.valid?
  end
end

MTest::Unit.new.run
