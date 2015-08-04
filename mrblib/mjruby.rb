def is_cygwin
  false
end

def cp_delim
  ":"
end

def debug(msg)
  puts msg if ENV['MJRUBY_DEBUG']
end

def warn(msg)
  puts "WARNING: #{msg}"
end

def resolve_jruby_home
  # TODO consider symlinks?
  ENV['JRUBY_HOME'] || File.expand_path("..", Dir.pwd)
end

def resolve_jruby_classpath(jruby_home)
  cp_ary = []
  jruby_already_added = false
  ["jruby.jar", "jruby-complete.jar"].each do |jruby_jar|
    full_path_to_jar = "#{jruby_home}/lib/#{jruby_jar}"
    if File.exist?(full_path_to_jar)
      warn("more than one JRuby JAR found in lib directory") if jruby_already_added
      cp_ary << full_path_to_jar
      jruby_already_added = true
    end
  end
  cp_ary << "#{jruby_home}/lib/jruby-truffle.jar"
  cp_ary.join(cp_delim)
end

def resolve_classpath(jruby_home)
  if ENV['JRUBY_PARENT_CLASSPATH']
    ENV['JRUBY_PARENT_CLASSPATH']
  else
    cp_ary = []
    Dir.foreach("#{jruby_home}/lib") do |filename|
      if filename.end_with?(".jar")
        unless ["jruby.jar", "jruby-complete.jar"].include?(filename)
          cp_ary << "#{jruby_home}/lib/#{filename}"
        end
      end
    end
    cp_ary.join(cp_delim)
  end
end

def java_opts(add_java_opts)
  (ENV['JAVA_OPTS'] ? ENV['JAVA_OPTS'].split(" ") : []) + add_java_opts.compact
end

def jffi_opts(jruby_home)
  ["-Djffi.boot.library.path=#{jruby_home}/lib/jni"]
end

def __main__(argv)
  command = argv.shift
  cli_opts = JRubyOptsParser.parse!(argv)
  java_class = "org.jruby.Main"
  javacmd = cli_opts.java_cmd || JavaSupport.resolve_java_command
  jruby_home = resolve_jruby_home
  jruby_shell = "/bin/sh"
  jruby_cp = resolve_jruby_classpath(jruby_home)
  classpath = resolve_classpath(jruby_home)
  jruby_opts = cli_opts.jruby_opts

  all_args = java_opts(cli_opts.java_opts) + jffi_opts(jruby_home) + [
    "-Xbootclasspath/a:#{jruby_cp}",
    "-classpath", "#{jruby_cp}#{cp_delim}#{classpath}",
    "-Djruby.home=#{jruby_home}",
    "-Djruby.lib=#{jruby_home}/lib",
    "-Djruby.script=jruby",
    "-Djruby.shell=#{jruby_shell}",
    java_class
  ] + cli_opts.ruby_opts
  debug "#{javacmd} #{all_args.join(' ')}"
  JavaSupport.exec javacmd, *all_args
end
