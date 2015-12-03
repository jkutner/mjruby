require 'rbconfig'
require 'fileutils'

# There must be a Makefile or RubyGems will freak out. So we create
# a no-op Makefile
File.write('Makefile', <<EOF)
clean:

install:
EOF

bindir = RbConfig::CONFIG['bindir']
FileUtils.cp("mruby/build/x86_64-apple-darwin14/bin/mjruby", bindir)
