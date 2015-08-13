class JRubySupport

  attr_reader :jruby_home

  def initialize(cmd)
    @jruby_home = resolve_jruby_home(cmd)
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
    if cmd.start_with?(File::SEPARATOR) #|| cmd[1..2] == ":#{File::SEPARATOR}"
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
end
