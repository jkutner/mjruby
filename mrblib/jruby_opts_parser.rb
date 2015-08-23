class JRubyOptsParser

  def self.parse!(opts)
    p = new(opts)
    raise ArgumentError.new("Invalid CLI Options") unless p.valid?
    p
  end

  attr_reader :ruby_opts
  attr_reader :jruby_opts
  attr_reader :java_cmd
  attr_reader :classpath
  attr_reader :java_encoding
  attr_reader :java_vm
  attr_reader :verify_jruby

  def initialize(opts)
    @raw_opts = opts
    @java_opts = []
    @ruby_opts = []
    @classpath = []
    parse(opts)
  end

  def valid?
    @valid
  end

  def java_mem
    @java_mem || '-Xmx500m'
  end

  attr_reader :java_mem_min

  def java_stack
    @java_stack || '-Xss2048k'
  end

  def java_opts
    [java_mem, java_mem_min, java_stack].compact + @java_opts
  end

  private

  def parse(opts)
    while !opts.empty? do
      opt = opts.shift
      if opt.start_with?("-J")
        java_opt = opt[2..-1]
        if java_opt.start_with?("-Xmx")
          @java_mem = java_opt
        elsif java_opt.start_with?("-Xms")
          @java_mem_min = java_opt
        elsif java_opt.start_with?("-Xss")
          @java_stack = java_opt
        elsif java_opt.empty?
          # TODO Need out of process Java before we can do this...
          # JavaSupport.system_java "-help"
          puts "(Prepend -J in front of these options when using 'jruby' command)"
          @valid = false
          return
        elsif java_opt.start_with?("-X")
          # TODO Need out of process Java before we can do this...
          # JavaSupport.system_java "-X"
          puts "(Prepend -J in front of these options when using 'jruby' command)"
          @valid = false
          return
        elsif java_opt.start_with?("-cp") || java_opt.start_with?("-classpath")
          @classpath << opts.shift
        elsif java_opt.start_with?("-ea")
          @verify_jruby = true
          @java_opts << java_opt
        elsif java_opt.start_with?("-Dfile.encoding=")
          @java_encoding = java_opt
          @java_opts << java_opt
        else
          @java_opts << java_opt
        end
      elsif is_ruby_x_arg?(opt) # /^((-X.*\.\.\.)|(-X.*\?))/
        # Pass -X... and -X? search options through
        @ruby_opts << opt
      elsif opt.start_with?("-X")
        val = opt[2..-1]
        if val.include?('.')
          # Match -Xa.b.c=d to translate to -Da.b.c=d as a java option
          @java_opts << "-Djruby.#{val}"
        else
          @ruby_opts << opt
        end
      elsif ['-C', '-e', '-I', '-S'].include?(opt[0..1])
        # Match switches that take an argument
        opt += opts.shift if opt.size == 2
        @ruby_opts << opt
      elsif opt == "--manage"
        @java_opts << "-Dcom.sun.management.jmxremote"
        @java_opts << "-Djruby.management.enabled=true"
      elsif opt == "--headless"
        @java_opts << "-Djava.awt.headless=true"
      # TODO Need out of process Java before we can do this...
      # elsif opt == "--jdb"
      #   @java_cmd = JavaSupport.resolve_java_command("jdb")
      #   @java_opts += ["-sourcepath", "$JRUBY_HOME/lib/ruby/1.9:."]
      elsif opt == "--client"
        @java_vm = "-client"
      elsif opt == "--server"
        @java_vm = "-server"
      elsif opt == "--no-client"
        @java_vm = nil
      elsif opt == "--dev"
        @java_vm = "-client"
        @java_opts << "-XX:+TieredCompilation"
        @java_opts << "-XX:TieredStopAtLevel=1"
        @java_opts << "-Djruby.compile.mode=OFF"
        @java_opts << "-Djruby.compile.invokedynamic=false"
      elsif opt == "--sample"
        @java_opts << "-Xprof"
      elsif opt == "--1.8"
       puts "warning: --1.8 ignored"
      elsif opt == "--1.9"
        puts "warning: --1.9 ignored"
      elsif opt == "--2.0"
        puts "warning: --2.0 ignored"
      elsif opt == "--"
        # Abort processing on the double dash
        opts.clear
      elsif opt.start_with?("-")
        # send the rest of the options to Ruby
        @ruby_opts << opt
      else
        # Abort processing on first non-opt arg
        @ruby_opts << opt
        @ruby_opts += opts
        opts.clear
      end
    end
    @valid = true
  end

  def is_ruby_x_arg?(opt)
    # effectively: /^((-X.*\.\.\.)|(-X.*\?))/
    if opt.start_with?("-X")
      if opt.end_with?("?")
        return true
      end
      return opt.chars.select{|c|  c == '.' }.size == 3
    end
    false
  end
end
