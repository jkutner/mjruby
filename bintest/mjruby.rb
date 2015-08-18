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
        "#{BIN_PATH} -rwebrick -e 'puts WEBrick::HTTPServer.new(:Port => 3000, :DocumentRoot => Dir.pwd)'")
      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "WEBrick::HTTPServer"
    end
  end
end
