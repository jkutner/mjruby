class TestJavaSupport < MTest::Unit::TestCase

  def test_resolve_java_command_from_java_home
    ENV['JAVACMD'] = nil
    ENV['JAVA_HOME'] = "/opt/jdk"
    assert_equal "/opt/jdk/bin/java", JavaSupport.resolve_java_command
  end

  def test_resolve_java_command_from_javacmd
    ENV['JAVACMD'] = "/usr/bin/java"
    ENV['JAVA_HOME'] = "/opt/bin"
    assert_equal "/usr/bin/java", JavaSupport.resolve_java_command
  end
end

MTest::Unit.new.run
