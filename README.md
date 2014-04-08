# Byebug
[![Version][VersionBadge]][VersionURL]
[![Build][TravisBadge]][TravisURL]
[![Climate][CodeClimateBadge]][CodeClimateURL]
[![Dependencies][GemnasiumBadge]][GemnasiumURL]
[![Coverage][CoverallsBadge]][CoverallsURL]
[![Gittip][GittipBadge]][GittipURL]

_Debugging in Ruby 2_

Byebug is a simple to use, feature rich debugger for Ruby 2. It uses the new
TracePoint API for execution control and the new Debug Inspector API for call
stack navigation, so it doesn't depend on internal core sources. It's developed
as a C extension, so it's fast. And it has a full test suite so it's reliable.

It allows you to see what is going on _inside_ a Ruby program while it executes
and can do four main kinds of things to help you catch bugs in the act:

* Start your program or attach to it, specifying anything that might affect its
behavior.
* Make your program stop on specified conditions.
* Examine what has happened when your program has stopped.
* Change things in your program, so you can experiment with correcting the
effects of one bug and go on to learn about another.


## Install

    $ gem install byebug


## Usage

Simply drop

    byebug

wherever you want to start debugging and the execution will stop there. If you
are debugging rails, start the server and once the execution gets to your
`byebug` command you will get a debugging prompt.

Former [debugger](https://github.com/cldwalker/debugger) or
[ruby-debug](https://github.com/mark-moseley/ruby-debug) users, notice:

* Some gems (rails, rspec) implement debugging flags (-d, --debugger) that early
require and start the debugger. These flags are a performance penalty and Byebug
doesn't need them anymore so my recommendation is not to use them.
* The startup configuration file is now called `.byebugrc` instead of
`.rdebugrc`.


## What's different from debugger

* Works on Ruby 2.x but it doesn't on 1.9.x (you should probably upgrade
anyways).
* Has no MRI internal source code dependencies, just a clean API (no more `bump
ruby_core_source dependency` entries in CHANGELOG, no more broken debugger's on
ruby's releases).
* Fixes a lot of debugger's issues, such as ruby 2.x support or post_mortem
debugging. It also provides several enhancements, such as the fact the `byebug`
can now be placed at the end of a block or method call.
* Actively mantained.
* Editor agnostic: no external editor built-in support.
* Pry command is built-in. No need of external gem like debugger-pry.


## Byebug's commands

    Command     | Aliases      | Subcommands
    ----------- |:------------ |:-----------
    `backtrace` | `bt` `where` |
    `break`     |              |
    `catch`     |              |
    `condition` |              |
    `continue`  |              |
    `delete`    |              |
    `disable`   |              | `breakpoints` `display`
    `display`   |              |
    `down`      |              |
    `edit`      |              |
    `enable`    |              | `breakpoints` `display`
    `finish`    |              |
    `frame`     |              |
    `help`      |              |
    `info`      |              | `args` `breakpoints` `catch` `display` `file` `files` `global_variables` `instance_variables` `line` `locals` `program` `stack` `variables`
    `irb`       |              |
    `kill`      |              |
    `list`      |              |
    `method`    |              | `instance` `iv`
    `next`      |              |
    `p`         | `eval`       |
    `pp`        |              |
    `pry`       |              |
    `ps`        |              |
    `putl`      |              |
    `quit`      | `exit`       |
    `reload`    |              |
    `restart`   |              |
    `save`      |              |
    `set`       |              | `args` `autoeval` `autoirb` `autolist` `autoreload` `autosave` `basename` `callstyle` `callstyle` `forcestep` `fullpath` `histfile` `histsize` `linetrace` `linetrace_plus` `listsize` `post_mortem` `stack_on_error` `testing` `verbose` `width`
    `show`      |              | `args` `autoeval` `autoirb` `autolist` `autoreload` `autosave` `basename` `callstyle` `callstyle` `commands` `forcestep` `fullpath` `histfile` `histsize` `linetrace` `linetrace_plus` `listsize` `post_mortem` `stack_on_error` `verbose` `width`
    `skip`      |              |
    `source`    |              |
    `step`      |              |
    `thread`    |              | `current` `list` `resume` `stop` `switch`
    `trace`     |              |
    `undisplay` |              |
    `up`        |              |
    `var`       |              | `class` `constant` `global` `instance` `local` `ct`


## Semantic Versioning

Byebug tries to follow [semantic versioning](http://semver.org) and tries to
bump major version only when backwards incompatible changes are released.
Backwards compatibility is targeted to
[pry-byebug](https://github.com/deivid-rodriguez/pry-byebug) and any other
plugins relying on `byebug`.


## Getting Started

Read [byebug's markdown
guide](https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md) to get
started. Proper documentation will be eventually written.


## Related projects

* [pry-byebug](https://github.com/deivid-rodriguez/pry-byebug) adds `next`,
`step`, `finish`, `continue` and `break` commands to pry using byebug.
* [ruby-debug-passenger](https://github.com/davejamesmiller/ruby-debug-passenger)
adds a rake task that restarts Passenger with byebug connected.
* [minitest-byebug](https://github.com/kaspth/minitest-byebug) starts a byebug
session on minitest failures.
* [sublime-debugger](https://github.com/shuky19/sublime_debugger) provides a plugin
for ruby debugging on Sublime Text.


## TODO List (by priority)

* Write tests for remote debugging support.
* Add printers support.
* Libify and test byebug's executable.
* Support rubies other than MRI.

## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* @ko1, author of the awesome TracePoint API for Ruby.
* @cldwalker, [debugger](https://github.com/cldwalker/debugger)'s mantainer.
* @denofevil, author of [debase](https://github.com/denofevil/debase), the
starting point of this.
* @kevjames3 for testing, bug reports and the interest in the project.
* @FooBarWidget for working and helping with remote debugging.

[VersionBadge]: https://badge.fury.io/rb/byebug.svg
[VersionURL]: http://badge.fury.io/rb/byebug
[TravisBadge]: https://travis-ci.org/deivid-rodriguez/byebug.svg
[TravisURL]: http://travis-ci.org/deivid-rodriguez/byebug
[CodeClimateBadge]: https://img.shields.io/codeclimate/github/deivid-rodriguez/byebug.svg
[CodeClimateURL]: https://codeclimate.com/github/deivid-rodriguez/byebug
[GemnasiumBadge]: https://gemnasium.com/deivid-rodriguez/byebug.svg
[GemnasiumURL]: https://gemnasium.com/deivid-rodriguez/byebug
[CoverallsBadge]: http://img.shields.io/coveralls/deivid-rodriguez/byebug.svg
[CoverallsURL]: https://coveralls.io/r/deivid-rodriguez/byebug
[GittipBadge]: http://img.shields.io/gittip/deivid-rodriguez.svg
[GittipURL]: https://www.gittip.com/deivid-rodriguez
