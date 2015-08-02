require 'open3'
require 'tmpdir'

BIN_PATH = File.join(File.dirname(__FILE__), "../mruby/bin/mjruby")

assert('setup') do
  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      output, status = Open3.capture2("#{BIN_PATH}")

      assert_true status.success?, "Process did not exit cleanly"
      assert_include output, "Hello World"
    end
  end
end
