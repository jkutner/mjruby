class JavaSupport

  def initialize
    @java_home = resolve_java_home
  end

  def resolve_java_home
    if ENV['JAVACMD']
      java_bin = File.dirname(ENV['JAVACMD'])
      File.dirname(java_bin)
    elsif ENV['JAVA_HOME']
      if JavaSupport.is_cygwin
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

  def exec_java(java_class, opts, args)
    Kernel.exec_java @java_home, java_class, opts.size, *(opts + args)
  end

  def self.is_cygwin
    false
  end

  def self.cp_delim
    # TODO Windows?
    is_cygwin ? ";" : ":"
  end
end
