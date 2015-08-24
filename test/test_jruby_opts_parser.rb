class TestJrubyOptsParser < MTest::Unit::TestCase

  def test_parse_java_opts
    parser = JRubyOptsParser.parse!(["-J-Xmx1g"])
    assert_includes parser.java_opts, "-Xmx1g"
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["-J-Xms1g"])
    assert_includes parser.java_opts, '-Xms1g'
    assert_includes parser.java_opts, '-Xmx500m'
    assert parser.valid?

    parser = JRubyOptsParser.parse!(['-J-Djruby.thread.pooling=true'])
    assert_includes parser.java_opts, '-Djruby.thread.pooling=true'
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--manage"])
    assert_includes parser.java_opts, "-Dcom.sun.management.jmxremote"
    assert_includes parser.java_opts, "-Djruby.management.enabled=true"
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--headless"])
    assert_includes parser.java_opts, "-Djava.awt.headless=true"
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--sample"])
    assert_includes parser.java_opts, "-Xprof"
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["--dev"])
    assert_includes parser.java_opts, "-XX:+TieredCompilation"
    assert_includes parser.java_opts, "-XX:TieredStopAtLevel=1"
    assert_includes parser.java_opts, "-Djruby.compile.mode=OFF"
    assert_includes parser.java_opts, "-Djruby.compile.invokedynamic=false"
    assert parser.valid?
  end

  def test_parse_ruby_opts

  end

  def test_parse_ruby_opts_with_args
    parser = JRubyOptsParser.parse!(["-Ctmp"])
    assert_equal ["-Ctmp"], parser.ruby_opts
    assert parser.valid?
    parser = JRubyOptsParser.parse!(["-C", "tmp"])
    assert_equal ["-Ctmp"], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse!(['-e"puts 1"'])
    assert_equal ['-e"puts 1"'], parser.ruby_opts
    assert parser.valid?
    parser = JRubyOptsParser.parse!(['-e', 'puts 1'])
    assert_equal ['-eputs 1'], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse!(['-Ilib'])
    assert_equal ['-Ilib'], parser.ruby_opts
    assert parser.valid?
    parser = JRubyOptsParser.parse!(['-I', 'lib'])
    assert_equal ['-Ilib'], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse!(['-Srake'])
    assert_equal ['-Srake'], parser.ruby_opts
    assert parser.valid?
    parser = JRubyOptsParser.parse!(['-S', 'rake'])
    assert_equal ['-Srake'], parser.ruby_opts
    assert parser.valid?
  end

  def test_parse_x_opts
    parser = JRubyOptsParser.parse!(["-Xcompile.invokedynamic=true"])
    assert_includes parser.java_opts, "-Djruby.compile.invokedynamic=true"
    assert_equal [], parser.ruby_opts
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["-X+O"])
    assert_includes parser.ruby_opts, "-X+O"
    assert parser.valid?
  end

  def test_verify_jruby
    parser = JRubyOptsParser.parse!(["-J-ea..."])
    assert_includes parser.java_opts, "-ea..."
    assert_equal [], parser.ruby_opts
    assert_true parser.verify_jruby, "verify_jruby should be 'true'"
    assert parser.valid?

    # TODO
  end

  def test_parse_3_dots_or_?
    # TODO
  end

  def test_defaults
    parser = JRubyOptsParser.parse!([])
    assert_equal [], parser.ruby_opts
    assert_equal ['-Xmx500m','-Xss2048k'], parser.java_opts
    assert_equal [], parser.classpath
    assert parser.valid?
  end

  def test_double_dash
    parser = JRubyOptsParser.parse!(["--", "-e", "1"])
    assert_equal [], parser.ruby_opts
    assert parser.valid?
  end

  def test_dash_star
    parser = JRubyOptsParser.parse!(["-rwebrick", "-Xcompile.invokedynamic=true"])
    assert_equal parser.ruby_opts, ["-rwebrick"]
    assert_includes parser.java_opts, "-Djruby.compile.invokedynamic=true"
    assert parser.valid?
  end

  def test_file_encoding
    parser = JRubyOptsParser.parse!(["-J-Dfile.encoding=UTF-8"])
    assert_includes parser.java_opts, "-Dfile.encoding=UTF-8"
    assert_equal parser.java_encoding, "-Dfile.encoding=UTF-8"
    assert parser.valid?
  end

  def test_classpath
    parser = JRubyOptsParser.parse!(["-J-cp", "foo/bar.jar"])
    assert_includes parser.classpath, "foo/bar.jar"
    assert parser.valid?

    parser = JRubyOptsParser.parse!(["-J-classpath", "foo/bar.jar"])
    assert_includes parser.classpath, "foo/bar.jar"
    assert parser.valid?

    # it's a little weird that we don't split the string into it's path parts
    # but it's not worth it
    parser = JRubyOptsParser.parse!(["-J-cp", "foo.jar:bar/*"])
    assert_includes parser.classpath, "foo.jar:bar/*"
    assert parser.valid?
  end

  def test_parse_errors
    # assert_raise Error do
    #   JRubyOptsParser.parse!(["asdjkashf"])
    # end
  end

  def assert_includes val_array, expected_val
    assert_true val_array.include?(expected_val), "Expected #{val_array} to include #{expected_val}"
  end
end

MTest::Unit.new.run
