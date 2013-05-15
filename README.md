# Byebug [![Gem Version](https://badge.fury.io/rb/byebug.png)](http://badge.fury.io/rb/byebug) [![Build Status](https://secure.travis-ci.org/deivid-rodriguez/byebug.png)](http://travis-ci.org/deivid-rodriguez/byebug) [![Code Climate](https://codeclimate.com/github/deivid-rodriguez/byebug.png)](https://codeclimate.com/github/deivid-rodriguez/byebug) [![Dependency Status](https://gemnasium.com/deivid-rodriguez/byebug.png)](https://gemnasium.com/deivid-rodriguez/byebug)

_Debugging in Ruby 2.0_

Byebug is a simple to use, feature rich debugger for Ruby 2.0. It uses the new
TracePoint API, so it doesn't depend on internal core sources. It's developed as
a C extension, so it's fast. And it has a full test suite so it's (I hope)
reliable.

## Install

Just drop

    gem 'byebug'

in your Gemfile and run

    bundle install


## Usage

Simply drop `byebug` wherever you want to start debugging and the execution
stop there. If you are debugging rails, start the server in normal mode with
`rails server` and once the execution get to your `byebug` command you will get
a debugging terminal.


## Configuration

You can automatically load some configurations at startup by dropping them in
the startup file `.byebugrc`. For example, you can change the number of lines
listed whenever byebug stops like this:

    set listsize 20

If you are coming from [debugger](https://github.com/cldwalker/debugger), notice
however that you no longer need

    set autoreload

because it is a default option in byebug.


## Related projects

* [pry-byebug](https://github.com/deivid-rodriguez/pry-byebug) adds `next`,
  `step`, `finish`, `continue` and `break` commands to pry using byebug.


## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* Kent Sibilev and Mark Moseley, original authors of
[ruby-debug](https://github.com/mark-moseley/ruby-debug).
* Gabriel Horner, [debugger](https://github.com/cldwalker/debugger)'s mantainer.
* Koichi Sasada, author of the new C debugging API for Ruby.
* Dennis Ushakov, author of [debase](https://github.com/denofevil/debase), the
starting point of this.
