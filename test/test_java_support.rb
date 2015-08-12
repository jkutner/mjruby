class TestJavaSupport < MTest::Unit::TestCase

  def host_java_home
    "/usr/lib/jvm/java-8-openjdk-amd64"
  end

  def test_resolve_jdk_home
    ENV['JAVACMD'] = nil
    ENV['JAVA_HOME'] = "/opt/jdk"
    j = JavaSupport.new
    assert_equal "/opt/jdk", j.java_home
    assert_equal "/opt/jdk/bin/java", j.java_exe
    assert_equal "/opt/jdk/jre/lib/amd64/server/libjvm.so", j.java_server_dl
    assert_equal "/opt/jdk/jre/lib/amd64/client/libjvm.so", j.java_client_dl
    assert_equal :jdk, j.runtime
  end

  def test_resolve_jre_home
    ENV['JAVACMD'] = nil
    ENV['JAVA_HOME'] = "/opt/jre"
    j = JavaSupport.new
    assert_equal "/opt/jre", j.java_home
    assert_equal "/opt/jre/bin/java", j.java_exe
    assert_equal nil, j.java_server_dl
    assert_equal "/opt/jre/lib/amd64/client/libjvm.so", j.java_client_dl
    assert_equal :jre, j.runtime
  end

  def test_resolve_javacmd
    ENV['JAVACMD'] = "/opt/jre/bin/java"
    ENV['JAVA_HOME'] = host_java_home
    j = JavaSupport.new
    assert_equal "/opt/jre", j.java_home
    assert_equal "/opt/jre/bin/java", j.java_exe
    assert_equal nil, j.java_server_dl
    assert_equal "/opt/jre/lib/amd64/client/libjvm.so", j.java_client_dl
    assert_equal :jre, j.runtime
  end

  def test_resolve_alt_javacmd
    ENV['JAVACMD'] = "/opt/jdk/bin/jdb"
    ENV['JAVA_HOME'] = host_java_home
    j = JavaSupport.new
    assert_equal "/opt/jdk", j.java_home
    assert_equal "/opt/jdk/bin/jdb", j.java_exe
    assert_equal "/opt/jdk/jre/lib/amd64/server/libjvm.so", j.java_server_dl
    assert_equal "/opt/jdk/jre/lib/amd64/client/libjvm.so", j.java_client_dl
    assert_equal :jdk, j.runtime
  end

  def test_resolve_native
    ENV['JAVACMD'] = nil
    ENV['JAVA_HOME'] = nil
    j = JavaSupport.new
    assert_equal host_java_home, j.java_home
    assert_equal "#{host_java_home}/bin/java", j.java_exe
    assert_equal "#{host_java_home}/jre/lib/amd64/server/libjvm.so", j.java_server_dl
    assert_equal nil, j.java_client_dl
    assert_equal :jdk, j.runtime
  end
end

MTest::Unit.new.run
