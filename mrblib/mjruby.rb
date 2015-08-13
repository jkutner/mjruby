def debug(msg)
  puts msg if ENV['MJRUBY_DEBUG']
end

def warn(msg)
  puts "WARNING: #{msg}"
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
  jruby_support = JRubySupport.new(command)
  cli_opts = JRubyOptsParser.parse!(jruby_opts_env + argv)
  java_class = "org/jruby/Main"
  jruby_home = jruby_support.jruby_home
  jruby_cp = jruby_support.jruby_classpath
  classpath = jruby_cp + JavaSupport.cp_delim + (
      cli_opts.classpath +
      jruby_support.classpath
    ).map{|f| File.realpath(f)}.join(JavaSupport.cp_delim)
  jruby_opts = cli_opts.jruby_opts

  all_java_opts = java_opts(cli_opts.java_opts) + jffi_opts(jruby_home) + [
    JRubySupport::DEFAULT_JAVA_OPTS,
    "-Xbootclasspath/a:#{jruby_cp}",
    "-Djava.class.path=#{classpath}",
    "-Djruby.home=#{jruby_home}",
    "-Djruby.lib=#{jruby_home}/lib",
    "-Djruby.script=jruby",
    "-Djruby.shell=#{JRubySupport::SYSTEM_SHELL}"
  ].select{|o| !o.empty? }

  if cli_opts.verify_jruby
    # TODO ???
  else
    debug "java #{all_java_opts} #{java_class} #{cli_opts.ruby_opts}"
    JavaSupport.new.exec_java(java_class, all_java_opts, cli_opts.ruby_opts)
  end
end
