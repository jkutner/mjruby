class JRubySupport

  attr_reader :jruby_home
  attr_reader :jruby_classpath
  attr_reader :classpath

  def initialize(cmd)
    @jruby_home = resolve_jruby_home(cmd)
    @jruby_classpath = resolve_jruby_classpath
    @classpath = resolve_classpath
  end

  def java_opts(add_java_opts)
    add_java_opts.compact
    (ENV['JAVA_OPTS'] ? ENV['JAVA_OPTS'].split(" ") : []) + add_java_opts.compact
  end

  def jffi_opts
    ["-Djffi.boot.library.path=#{jruby_home}/lib/jni"]
  end

  def jruby_opts_env
    (ENV['JRUBY_OPTS'] ? ENV['JRUBY_OPTS'].split(' ') : []).select{|opt| !opt.empty?}.compact
  end

  def default_java_opts
    [JRubySupport::DEFAULT_JAVA_OPTS].select{|o| !o.empty? }
  end

  def search_path(cmd)
    # This could affect start up time
    path_items = ENV['PATH'].split(File::PATH_SEPARATOR)
    path_items.each do |path_item|
      Dir.foreach(path_item) do |filename|
        if filename == cmd || filename == "#{cmd}.exe"
          return path_item
        end
      end if Dir.exist?(path_item)
    end
    nil
  end

  def resolve_exe_path(cmd)
    if cmd.start_with?(File::SEPARATOR) || cmd[1..2] == ":#{File::SEPARATOR}"
      return File.expand_path("..#{File::SEPARATOR}..", cmd)
    else
      from_path = search_path(cmd)
      return File.expand_path("..", from_path) if from_path
    end
    File.join(Dir.pwd, cmd) # must be relative
  end

  def resolve_jruby_home(cmd)
    jruby_home = ENV['JRUBY_HOME'] || resolve_exe_path(cmd)
    unless Dir.exists?(File.join(jruby_home, "lib"))
      raise "JRUBY_HOME directory is malformed: no lib directory found!"
    end
    jruby_home
  end

  def resolve_jruby_classpath
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
    # FIXME this doesn't work on windows. org/jruby/Main isn't found.
    # cp_ary << File.join(jruby_home, "lib", "jruby-truffle.jar")
    raise "No JRuby JAR found in lib directory!" if cp_ary.empty?
    cp_ary.join(JavaSupport.cp_delim)
  end

  def resolve_classpath
    if ENV['JRUBY_PARENT_CLASSPATH']
      ENV['JRUBY_PARENT_CLASSPATH'].split(JavaSupport.cp_delim)
    else
      cp_ary = []
      Dir.foreach(File.join(jruby_home, "lib")) do |filename|
        if filename.end_with?(".jar")
          unless ["jruby.jar", "jruby-complete.jar"].include?(filename)
            cp_ary << File.join(jruby_home, "lib", filename)
          end
        end
      end
      cp_ary
    end
  end
end
