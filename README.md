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

* Works on Ruby 2.x and it doesn't on 1.9.x.
* Has no MRI internal source code dependencies, just a clean API.
* Fixes all of debugger's open bugs in its issue tracker and provides some
enhancements, such as a markdown guide or the fact that `byebug` can now be
placed at the end of a block or method call.
* Actively mantained.
* Editor agnostic: no external editor built-in support.
* Pry command is built-in. No need of external gem like debugger-pry.


## Semantic Versioning

Byebug tries to follow [semantic versioning](http://semver.org). Backwards
compatibility doesn't seem like a critic issue for a debugger because it's not
supposed to be used permanently by any program, let alone in production
environments. However, I still like the idea of giving some meaning to version
changes.

Byebug's public API is determined by its set of commands

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
    `set`       |              | `args` `autoeval` `autoirb` `autolist` `autoreload` `basename` `callstyle` `callstyle` `forcestep` `fullpath` `history` `linetrace` `linetrace_plus` `listsize` `post_mortem` `stack_on_error` `testing` `verbose` `width`
    `show`      |              | `args` `autoeval` `autoirb` `autolist` `autoreload` `basename` `callstyle` `callstyle` `commands` `forcestep` `fullpath` `history` `linetrace` `linetrace_plus` `listsize` `post_mortem` `stack_on_error` `verbose` `width`
    `skip`      |              |
    `source`    |              |
    `step`      |              |
    `thread`    |              | `current` `list` `resume` `stop` `switch`
    `trace`     |              |
    `undisplay` |              |
    `up`        |              |
    `var`       |              | `class` `constant` `global` `instance` `local` `ct`


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


## Future (possible) directions

* JRuby support.
* Libify and test byebug's executable.
* Add printers support.


## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* Kent Sibilev and Mark Moseley, original authors of
[ruby-debug](https://github.com/mark-moseley/ruby-debug).
* Gabriel Horner, [debugger](https://github.com/cldwalker/debugger)'s mantainer.
* Koichi Sasada, author of the new C debugging API for Ruby.
* Dennis Ushakov, author of [debase](https://github.com/denofevil/debase), the
starting point of this.
* @kevjames3 for testing, bug reports and the interest in the project.

[VersionBadge]: https://badge.fury.io/rb/byebug.png
[VersionURL]: http://badge.fury.io/rb/byebug
[TravisBadge]: https://travis-ci.org/deivid-rodriguez/byebug.png
[TravisURL]: http://travis-ci.org/deivid-rodriguez/byebug
[CodeClimateBadge]: https://codeclimate.com/github/deivid-rodriguez/byebug.png
[CodeClimateURL]: https://codeclimate.com/github/deivid-rodriguez/byebug
[GemnasiumBadge]: https://gemnasium.com/deivid-rodriguez/byebug.png
[GemnasiumURL]: https://gemnasium.com/deivid-rodriguez/byebug
[CoverallsBadge]: https://coveralls.io/repos/deivid-rodriguez/byebug/badge.png
[CoverallsURL]: https://coveralls.io/r/deivid-rodriguez/byebug
[GittipBadge]: http://img.shields.io/gittip/deivid-rodriguez.png
[GittipURL]: https://www.gittip.com/deivid-rodriguez
