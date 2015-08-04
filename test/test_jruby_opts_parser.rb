class TestMjruby < MTest::Unit::TestCase

  def test_parse_java_opts
    parser = JRubyOptsParser.parse!(["-J-Xmx1g"])
    assert_true parser.java_opts.include?("-Xmx1g")
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["-J-Xms1g"])
    assert_true parser.java_opts.include?('-Xms1g')
    assert_true parser.java_opts.include?('-Xmx500m')
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["-Xcext.enabled=true"])
    assert_equal ["-Xcext.enabled=true"], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--manage"])
    assert_true parser.java_opts.include?("-Dcom.sun.management.jmxremote")
    assert_true parser.java_opts.include?("-Djruby.management.enabled=true")
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--headless"])
    assert_true parser.java_opts.include?("-Djava.awt.headless=true")
    assert parser.valid?
  end

  def test_parse_defaults
    parser = JRubyOptsParser.parse!([])
    assert_equal [], parser.ruby_opts
    assert_equal ['-Xmx500m','-Xss2048k'], parser.java_opts
    assert_equal [], parser.classpath
    assert parser.valid?
  end

  # def test_parse_defaults
  #   parser = JRubyOptsParser.parse!([])
  #   assert_equal [], parser.ruby_opts
  #   assert parser.valid?
  # end

  def test_parse_errors
    # assert_raise Error do
    #   JRubyOptsParser.parse!(["asdjkashf"])
    # end
  end
end

MTest::Unit.new.run
