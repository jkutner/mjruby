class JavaSupport
  def self.resolve_java_command(cmd="java")
    if cmd == "java" && ENV['JAVACMD']
      ENV['JAVACMD']
    elsif ENV['JAVA_HOME']
      if is_cygwin
        raise "No cygwin support yet :("
        # "`cygpath -u "$JAVA_HOME"`/bin/java"
      else
        "#{ENV['JAVA_HOME']}/bin/#{cmd}"
      end
    else
      path_items = ENV['PATH'].split(File::PATH_SEPARATOR)
      path_items.each do |path_item|
        Dir.foreach(path_item) do |filename|
          return "#{path_item}/#{cmd}" if filename == cmd
        end if Dir.exist?(path_item)
      end
      raise "No `#{cmd}' executable found on PATH."
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
end
