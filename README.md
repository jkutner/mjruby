# mjruby [![Build Status](https://travis-ci.org/jkutner/mjruby.svg?branch=master)](https://travis-ci.org/jkutner/mjruby)

This is a rewrite of the JRuby launcher. It uses
[mruby-cli](https://github.com/hone/mruby-cli) to
build binary executables of the `jruby` command.

This is very much in beta, and needs your help!

## Usage

1. Run `gem install mjruby`
2. Run JRuby by using `mjruby` instead of `jruby`.

Everything that works with the `jruby` command is supposed to work with
the `mjruby` command. Please create an issue if you find a difference.

If you really want to push it's limits, delete the `jruby` executable in your `JRUBY_HOME/bin` directory and rename the `mjruby` executable to `jruby`.

## Development

1. Install Docker
2. Install Docker-Compose
3. Run `docker-compose run compile`

And to run the tests:

1. Run `docker-compose run mtest`

## License

MIT
