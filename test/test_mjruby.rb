class TestMjruby < MTest::Unit::TestCase
  # def test_main
  #   assert_nil __main__
  # end

  def test_resolve_java_command_from_java_home
    ENV['JAVACMD'] = nil
    ENV['JAVA_HOME'] = "/opt/jdk"
    assert_equal "/opt/jdk/bin/java", resolve_java_command
  end

  def test_resolve_java_command_from_javacmd
    ENV['JAVACMD'] = "/usr/bin/java"
    ENV['JAVA_HOME'] = "/opt/bin"
    assert_equal "/usr/bin/java", resolve_java_command
  end
end

MTest::Unit.new.run
