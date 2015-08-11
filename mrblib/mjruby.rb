def debug(msg)
  puts msg if ENV['MJRUBY_DEBUG']
end

def warn(msg)
  puts "WARNING: #{msg}"
end

def resolve_jruby_home
  jruby_home = ENV['JRUBY_HOME'] || File.expand_path("..", Dir.pwd)
  unless Dir.exists?(File.join(jruby_home, "lib"))
    raise "JRUBY_HOME directory is malformed: no lib directory found!"
  end
  jruby_home
end

def resolve_jruby_classpath(jruby_home)
  cp_ary = []
  jruby_already_added = false
  ["jruby.jar", "jruby-complete.jar"].each do |jruby_jar|
    full_path_to_jar = File.join(jruby_home, "lib", jruby_jar)
    if File.exist?(full_path_to_jar)
      warn("More than one JRuby JAR found in lib directory") if jruby_already_added
      cp_ary << full_path_to_jar
      jruby_already_added = true
    end
  end
  # cp_ary << File.join(jruby_home, "lib", "jruby-truffle.jar")
  raise "No JRuby JAR found in lib directory!" if cp_ary.empty?
  cp_ary.map{|f| File.realpath(f)}.uniq.join(JavaSupport.cp_delim)
end

def resolve_classpath(jruby_home)
  # if ENV['JRUBY_PARENT_CLASSPATH']
  #   ENV['JRUBY_PARENT_CLASSPATH'].split(JavaSupport.cp_delim)
  # else
    cp_ary = []
    Dir.foreach(File.join(jruby_home, "lib")) do |filename|
      if filename.end_with?(".jar")
        unless ["jruby.jar", "jruby-complete.jar"].include?(filename)
          cp_ary << File.join(jruby_home, "lib", filename)
        end
      end
    end
    cp_ary
  # end
end

def java_opts(add_java_opts)
  add_java_opts.compact
  # FIXME
  # (ENV['JAVA_OPTS'] ? ENV['JAVA_OPTS'].split(" ") : []) + add_java_opts.compact
end

def jffi_opts(jruby_home)
  ["-Djffi.boot.library.path=#{jruby_home}/lib/jni"]
end

def jruby_opts_env
  # FIXME regex support is limited, so...
  # (ENV['JRUBY_OPTS'] ? ENV['JRUBY_OPTS'].split(' ') : []).select{|opt| !opt.empty?}.compact
  []
end

def __main__(argv)
  command = argv.shift
  cli_opts = JRubyOptsParser.parse!(jruby_opts_env + argv)
  java_class = "org/jruby/Main"
  jruby_home = resolve_jruby_home
  jruby_cp = resolve_jruby_classpath(jruby_home)
  classpath = jruby_cp + JavaSupport.cp_delim + (
      cli_opts.classpath +
      resolve_classpath(jruby_home)
    ).map{|f| File.realpath(f)}.uniq.join(JavaSupport.cp_delim)
  jruby_opts = cli_opts.jruby_opts

  all_java_opts = java_opts(cli_opts.java_opts) + jffi_opts(jruby_home) + [
    JavaSupport::DEFAULT_JAVA_OPTS,
    "-Xbootclasspath/a:#{jruby_cp}",
    "-Djava.class.path=#{classpath}",
    "-Djruby.home=#{jruby_home}",
    "-Djruby.lib=#{jruby_home}/lib",
    "-Djruby.script=jruby",
    "-Djruby.shell=#{JavaSupport::SYSTEM_SHELL}"
  ].select{|o| !o.empty? }

  if cli_opts.verify_jruby
    # TODO ???
  else
    debug "java #{all_java_opts} #{java_class} #{cli_opts.ruby_opts}"
    JavaSupport.new.exec_java(java_class, all_java_opts, cli_opts.ruby_opts)
  end
end
