def is_cygwin
  false
end

def cp_delim
  ":"
end

def debug(msg)
  puts msg if ENV['MJRUBY_DEBUG']
end

def resolve_java_command
  if ENV['JAVACMD']
    ENV['JAVACMD']
  elsif ENV['JAVA_HOME']
    if is_cygwin
      raise "No cygwin support yet :("
      # "`cygpath -u "$JAVA_HOME"`/bin/java"
    else
      "#{ENV['JAVA_HOME']}/bin/java"
    end
  else
    # TODO parse path
    raise "No `java' executable found on PATH."
  end
end

def resolve_jruby_home
  ENV['JRUBY_HOME'] || File.expand_path("..", Dir.pwd)
end

def resolve_jruby_classpath(jruby_home)
  # make better
  cp_ary = []
  Dir.foreach("#{jruby_home}/lib") do |filename|
    # make sure only one jruby on cp
    if filename.end_with?(".jar")
      cp_ary << "#{jruby_home}/lib/#{filename}"
    end
  end

  cp_ary.join(cp_delim)
end

def __main__(argv)
  java_class = "org.jruby.Main"
  javacmd = resolve_java_command
  jruby_home = resolve_jruby_home
  jruby_shell = "/bin/sh"
  jruby_cp = resolve_jruby_classpath(jruby_home)

  argv.shift
  java_args = [
    "-Xbootclasspath/a:#{jruby_cp}",
    "-classpath", jruby_cp,
    "-Djruby.home=#{jruby_home}",
    "-Djruby.lib=#{jruby_home}/lib",
    "-Djruby.script=jruby",
    "-Djruby.shell=#{jruby_shell}",
    java_class
  ] + argv
  debug "#{javacmd} #{java_args.join(' ')}"
  exec javacmd, *java_args
end
