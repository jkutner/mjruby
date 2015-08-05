class JavaSupport

  def self.java_home
    # if cmd == "java" && ENV['JAVACMD']
    #   java_bin = File.dirname(ENV['JAVACMD'])
    #   File.dirname(java_bin)
    if ENV['JAVA_HOME']
      if is_cygwin
        raise "No cygwin support yet :("
        # "`cygpath -u "$JAVA_HOME"`/bin/java"
      else
        ENV['JAVA_HOME']
      end
    else
      path_items = ENV['PATH'].split(File::PATH_SEPARATOR)
      path_items.each do |path_item|
        Dir.foreach(path_item) do |filename|
          return path_item if filename == "java"
        end if Dir.exist?(path_item)
      end
      raise "No JAVA_HOME found."
    end
  end

  def self.resolve_java_command(cmd="java")
    if cmd == "java" && ENV['JAVACMD']
      ENV['JAVACMD']
    else
      "#{java_home}/#{cmd}"
    end
  end

  def self.exec_java(*args)
    # TODO use libjvm
    Kernel.exec resolve_java_command, *args
  end

  def self.exec(java_cmd, *args)
    # TODO use libjvm
    Kernel.exec java_cmd, *args
  end

  def self.system_java(*args)
    # TODO use libjvm
    Kernel.exec resolve_java_command, *args
  end

  def self.system(java_cmd, *args)
    # TODO use libjvm
    Kernel.system java_cmd, *args
  end

  def self.is_cygwin
    false
  end

  def self.cp_delim
    # TODO Windows?
    is_cygwin ? ";" : ":"
  end
end
