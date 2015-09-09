require 'open3'
require 'tmpdir'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/mjruby")

assert('setup') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      output, status = Open3.capture2("#{BIN_PATH} -e \"puts 'Hello World'\"")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"

      output, status = Open3.capture2("#{BIN_PATH} -h")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Usage: jruby"

      output, status = Open3.capture2("#{BIN_PATH} -v")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "jruby 9.0.0.0 (2.2.2)"

      output, status = Open3.capture2(
        "#{BIN_PATH} --dev -rwebrick -J-Dsome.prop=foobar -J-Xmx256m -e \"puts 'Hello World'\"")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"

      output, status = Open3.capture2(
        "#{BIN_PATH} --spawn --dev -rwebrick -J-Dsome.prop=foobar -J-Xmx256m -e \"puts 'Hello World'\"")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"

      output, error, status = Open3.capture3(
        "#{BIN_PATH} -rwebrick -e 'puts WEBrick::HTTPServer.new(:Port => 3000, :DocumentRoot => Dir.pwd)'")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "WEBrick::HTTPServer"
      assert_include error, "INFO  WEBrick 1.3.1"

      output, error, status = Open3.capture3(
        "#{BIN_PATH} -J-X")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "(Prepend -J in front of these options when using 'jruby' command)"
      assert_include error, "The -X options are non-standard and subject to change without notice."

      output, error, status = Open3.capture3(
        "#{BIN_PATH} -J")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "(Prepend -J in front of these options when using 'jruby' command)"
      assert_include error, "Usage: java"

      output, status = Open3.capture2(
        "#{BIN_PATH} -J-ea -e \"puts 'Hello World'\"")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"

      output, status = Open3.capture2(
        "#{BIN_PATH} -S gem install bundler")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "1 gem installed"
    end
  end
end
