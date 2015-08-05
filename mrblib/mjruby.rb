def debug(msg)
  puts msg if ENV['MJRUBY_DEBUG']
end

def warn(msg)
  puts "WARNING: #{msg}"
end

def resolve_jruby_home
  # TODO consider symlinks?
  jruby_home = ENV['JRUBY_HOME'] || File.expand_path("..", Dir.pwd)
  Dir.foreach(jruby_home) do |dirname|
    return jruby_home if dirname == "lib"
  end
  raise "JRUBY_HOME directory is malformed: no lib directory found!"
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
  cp_ary.join(JavaSupport.cp_delim)
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
    cp_ary.join(JavaSupport.cp_delim)
  end
end

def java_opts(add_java_opts)
  (ENV['JAVA_OPTS'] ? ENV['JAVA_OPTS'].split(" ") : []) + add_java_opts.compact
end

def jffi_opts(jruby_home)
  ["-Djffi.boot.library.path=#{jruby_home}/lib/jni"]
end

def jruby_opts_env
  # regex support is limited, so...
  ENV['JRUBY_OPTS'].split(' ').select{|opt| !opt.empty?}.compact
end

def __main__(argv)
  command = argv.shift
  cli_opts = JRubyOptsParser.parse!(jruby_opts_env + argv)
  java_class = "org.jruby.Main"
  javacmd = cli_opts.java_cmd || JavaSupport.resolve_java_command
  jruby_home = resolve_jruby_home
  jruby_shell = "/bin/sh"
  jruby_cp = resolve_jruby_classpath(jruby_home)
  classpath = jruby_cp + JavaSupport.cp_delim
  classpath += cli_opts.classpath.join(JavaSupport.cp_delim) + JavaSupport.cp_delim
  classpath += resolve_classpath(jruby_home)
  jruby_opts = cli_opts.jruby_opts

  # Not really sure if this is needed
  ENV['JAVA_VM'] = cli_opts.java_vm

  # TODO detect darwin
  # java_encoding = cli_opts
  # java_encoding =|| "-Dfile.encoding=UTF-8"

  all_args = java_opts(cli_opts.java_opts) + jffi_opts(jruby_home) + [
    "-Xbootclasspath/a:#{jruby_cp}",
    "-classpath", classpath,
    "-Djruby.home=#{jruby_home}",
    "-Djruby.lib=#{jruby_home}/lib",
    "-Djruby.script=jruby",
    "-Djruby.shell=#{jruby_shell}",
    java_class
  ] + cli_opts.ruby_opts
  debug "#{javacmd} #{all_args.join(' ')}"

  if cli_opts.verify_jruby
    # TODO ???
  else
    puts JavaSupport.java_home
    puts "exec_java: #{exec_java(JavaSupport.java_home, javacmd, *all_args)}"
  end
end
