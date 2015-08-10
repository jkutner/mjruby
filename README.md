# mjruby

This is a rewrite of the JRuby launcher. It uses
[mruby-cli](https://github.com/hone/mruby-cli) to
build binary executables of the `jruby` command.

This is very much in beta, and needs your help!

## Usage

1. Download the precompiled `mjruby` binary for your System from the [releases page](https://github.com/jkutner/mjruby/releases).
2. Put the binary in the `$JRUBY_HOME/bin` dir (alongside the `jruby` command).
3. Run JRuby by using `mjruby` instead of `jruby`.

Everything that works with the `jruby` command is supposed to work with
the `mjruby` command. Please create an issue if you find a difference.

## Development

1. Install Docker
2. Install Docker-Compose
3. Run `docker-compose run compile`

## License

MIT
