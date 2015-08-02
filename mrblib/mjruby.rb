def resolve_java_command
  if ENV['JAVACMD']
    ENV['JAVACMD']
  elsif ENV['JAVA_HOME']
    "#{ENV['JAVA_HOME']}/bin/java"
  elsif is_cygwin
    raise "No cygwin support yet :("
    # "`cygpath -u "$JAVA_HOME"`/bin/java"
  else
    raise "No `java` command found."
  end
end

def __main__(argv)
  javacmd = resolve_java_command

  exec javacmd, "-version"
end
