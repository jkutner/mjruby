class JavaSupport

  attr_reader :java_home
  attr_reader :java_exe
  attr_reader :runtime
  attr_reader :java_server_dl
  attr_reader :java_client_dl

  def initialize
    resolve_java_home
  end

  def resolve_java_home
    if attempt_javacmd(ENV['JAVACMD'])
      return true
    elsif attempt_java_home(ENV['JAVA_HOME'])
      return true
    elsif resolve_native_java_home
      return true
    end
    raise "No JAVA_HOME found."
  end

  def resolve_native_java_home
    native_java_home = find_native_java
    if native_java_home
      native_java_home.strip!
      if native_java_home[-9..-1] == "/bin/java"
        native_java_home = File.expand_path("../..", native_java_home)
      end
      attempt_java_home(native_java_home)
    end
  end

  def attempt_javacmd(javacmd)
    if javacmd
      @java_exe = javacmd
      java_bin = File.dirname(javacmd)
      return attempt_java_home(File.dirname(java_bin))
    end
    false
  end

  def attempt_java_home(path)
    is_java_home?(path) do |runtime, exe, server_dl, client_dl|
      @runtime = runtime
      @java_exe ||= exe
      @java_server_dl = server_dl
      @java_client_dl = client_dl
      @java_home = path
    end
  end

  def is_java_home?(path, &block)
    is_jdk_home?(path, &block) ||
    is_jre_home?(path, &block) ||
    is_jdk9_home?(path, &block) ||
    false
  end

  def is_jdk_home?(path)
    if path and Dir.exists?(path)
      exe = exists_or_nil(resolve_java_exe(path))
      sdl = exists_or_nil(resolve_jdk_server_dl(path))
      cdl = exists_or_nil(resolve_jdk_client_dl(path))
      if exe and (cdl or sdl)
        yield :jdk, exe, sdl, cdl
      end
    end
  end

  def is_jdk9_home?(path)
    if path and Dir.exists?(path.strip!)
      exe = exists_or_nil(resolve_java_exe(path))
      sdl = exists_or_nil(resolve_jdk9_server_dl(path))
      if exe and sdl
        yield :jdk9, exe, sdl, nil
      end
    end
  end

  def is_jre_home?(path)
    if path and Dir.exists?(path)
      exe = exists_or_nil(resolve_java_exe(path))
      cdl = exists_or_nil(resolve_jre_client_dl(path))
      if exe and cdl
        yield :jre, exe, nil, cdl
      end
    end
  end

  def resolve_java_exe(java_home)
    File.join(java_home, "bin", JAVA_EXE)
  end

  def resolve_jdk_server_dl(java_home)
    File.join(java_home, "jre", JavaSupport::JAVA_SERVER_DL)
  end

  def resolve_jdk9_server_dl(java_home)
    File.join(java_home, JavaSupport::JAVA_SERVER_DL)
  end

  def resolve_jdk_client_dl(java_home)
    File.join(java_home, "jre", JavaSupport::JAVA_CLIENT_DL)
  end

  def resolve_jre_client_dl(java_home)
    File.join(java_home, JavaSupport::JAVA_CLIENT_DL)
  end

  def resolve_jli_dl
    if @runtime == :jdk
      File.join(@java_home, "jre", JavaSupport::JLI_DL)
    else
      File.join(@java_home, JavaSupport::JLI_DL)
    end
  end

  def resolve_java_dls(java_opts)
    client_i = java_opts.index("-client")
    server_i = java_opts.index("-server")
    if client_i.nil? && server_i.nil?
      java_dl = @java_server_dl || @java_client_dl
    elsif server_i
      java_dl = @java_server_dl
    elsif client_i
      java_dl = @java_client_dl
    elsif server_i < client_i
      java_dl = @java_client_dl
    else
      java_dl = @java_server_dl
    end

    raise "Could not find Java native library" if java_dl.nil?

    yield java_opts.select{|o| !["-client","-server"].include?(o) }, java_dl, resolve_jli_dl
  end

  def exec_java(java_class, java_opts, ruby_opts)
    resolve_java_dls(java_opts) do |parsed_java_opts, java_dl, jli_dl|
      all_opts = parsed_java_opts + ruby_opts
      Kernel.exec_java java_dl, jli_dl, java_class, parsed_java_opts.size, *all_opts
    end
  end

  def self.is_cygwin
    false
  end

  def self.cp_delim
    # TODO Windows?
    is_cygwin ? ";" : ":"
  end

  private

  def exists_or_nil(path)
    File.exists?(path) ? path : nil
  end
end
