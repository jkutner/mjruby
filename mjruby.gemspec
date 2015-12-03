# coding: utf-8
require './mrblib/version.rb'

Gem::Specification.new do |spec|
  spec.name          = "mjruby"
  spec.version       = MJRuby::VERSION
  spec.authors       = ["Joe Kutner", "Terence Lee"]
  spec.email         = ["jpkutner@gmail.com"]
  spec.platform      = "java"

  spec.summary       = %q{Native JRuby Launcher}
  spec.description   = %q{This is a rewrite of the JRuby launcher. It uses mruby-cli to build binary executables of the jruby command.}
  spec.homepage      = "https://github.com/jkutner/mjruby"
  spec.license       = "MIT"

  spec.files         = (["i386-apple-darwin14",
                         "x86_64-apple-darwin14",
                         "i686-pc-linux-gnu",
                         "x86_64-pc-linux-gnu",
                         "i686-pc-freebsd7",
                         "x86_64-pc-freebsd7",
                         ].map {|p| "#{p}/bin/mjruby"} +
                        ["i686-w64-mingw32",
                         "x86_64-w64-mingw32"
                         ].map {|p| "#{p}/bin/mjruby.exe"}
                       ).map {|f| "mruby/build/#{f}"}

  spec.extensions    = ["extconf.rb"]

  spec.add_development_dependency "rake", "~> 10.0"
end
