# Byebug
[![Version][VersionBadge]][VersionURL]
[![Build][TravisBadge]][TravisURL]
[![Climate][CodeClimateBadge]][CodeClimateURL]
[![Dependencies][GemnasiumBadge]][GemnasiumURL]
[![Coverage][CoverageBadge]][CoverageURL]
[![Gittip][GittipBadge]][GittipURL]

_Debugging in Ruby 2_

Byebug is a simple to use, feature rich debugger for Ruby 2. It uses the new
TracePoint API for execution control and the new Debug Inspector API for call
stack navigation, so it doesn't depend on internal core sources. It's developed
as a C extension, so it's fast. And it has a full test suite so it's reliable.

It allows you to see what is going on _inside_ a Ruby program while it executes
and offers many of the traditional debugging features such as:

* Stepping: Running your program one line at a time.
* Breaking: Pausing the program at some event or specified instruction, to
examine the current state.
* Evaluating: Basic REPL functionality, although [pry][] does a better job at
that.
* Tracking: Keeping track of the different values of your variables or the
different lines executed by your program.


## Ruby Version Support

Byebug works only for Ruby 2.0.0 or newer. For debugging ruby 1.9.3 or older,
use [debugger][].

Furthermore, Byebug uses the TracePoint API which was just first developed for
Ruby 2.0.0. Since it was released, a lot of bugs directly impacting Byebug have
been corrected, so for the best debugging experience, the following Ruby
versions are recommended:

* Ruby 2.0.0-p576 or higher.
* Ruby 2.1.3 or higher.
* Ruby 2.2.0-preview1 or higher.


## Install

    $ gem install byebug


## Usage

Simply drop

    byebug

wherever you want to start debugging and the execution will stop there. If you
are debugging rails, start the server and once the execution gets to your
`byebug` command you will get a debugging prompt.

Former [debugger][] or [ruby-debug][] users, notice:

* Some gems (rails, rspec) implement debugging flags (-d, --debugger) that early
require and start the debugger. These flags are a performance penalty and byebug
doesn't need them anymore so my recommendation is not to use them. In any case,
both rails and rspec have deprecated these flags in their latest versions.  
* The startup configuration file is now called `.byebugrc` instead of
`.rdebugrc`.


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
    `history`   |              |
    `info`      |              | `args` `breakpoints` `catch` `display` `file` `files` `line` `program`
    `irb`       |              |
    `kill`      |              |
    `list`      |              |
    `method`    |              | `instance`
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
    `set`       |              | `autoeval` `autoirb` `autolist` `autoreload` `autosave` `basename` `callstyle` `forcestep` `fullpath` `histfile` `histsize` `linetrace` `tracing_plus` `listsize` `post_mortem` `stack_on_error` `testing` `verbose` `width`
    `show`      |              | `autoeval` `autoirb` `autolist` `autoreload` `autosave` `basename` `callstyle` `forcestep` `fullpath` `histfile` `histsize` `linetrace` `tracing_plus` `listsize` `post_mortem` `stack_on_error` `testing` `verbose` `width`
    `skip`      |              |
    `source`    |              |
    `step`      |              |
    `thread`    |              | `current` `list` `resume` `stop` `switch`
    `tracevar`  |              |
    `undisplay` |              |
    `up`        |              |
    `var`       |              | `all` `class` `constant` `global` `instance` `local`


## Semantic Versioning

Byebug tries to follow [semantic versioning](http://semver.org) and tries to
bump major version only when backwards incompatible changes are released.
Backwards compatibility is targeted to [pry-byebug][] and any other plugins
relying on `byebug`.


## Getting Started

Read [byebug's markdown
guide](https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md) to get
started. Proper documentation will be eventually written.


## Related projects

* [pry-byebug][] adds `next`, `step`, `finish`, `continue` and `break` commands
to `pry` using `byebug`.
* [ruby-debug-passenger][] adds a rake task that restarts Passenger with Byebug
connected.
* [minitest-byebug][] starts a byebug session on minitest failures.
* [sublime_debugger][] provides a plugin for ruby debugging on Sublime Text.


## Contribute

See [Getting Started with Development](CONTRIBUTING.md).


## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* @ko1, author of the awesome TracePoint API for Ruby.
* @cldwalker, [debugger][]'s mantainer.
* @denofevil, author of [debase][], the starting point of this.
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
[CoverageBadge]: https://codeclimate.com/github/deivid-rodriguez/byebug/badges/coverage.svg
[CoverageURL]: https://codeclimate.com/github/deivid-rodriguez/byebug
[GittipBadge]: http://img.shields.io/gittip/deivid-rodriguez.svg
[GittipURL]: https://www.gittip.com/deivid-rodriguez

[debugger]: https://github.com/cldwalker/debugger
[pry]: https://github.com/pry/pry
[ruby-debug]: https://github.com/mark-moseley/ruby-debug
[debase]: https://github.com/denofevil/debase
[pry-byebug]: https://github.com/deivid-rodriguez/pry-byebug
[ruby-debug-passenger]: https://github.com/davejamesmiller/ruby-debug-passenger
[minitest-byebug]: https://github.com/kaspth/minitest-byebug
[sublime_debugger]: https://github.com/shuky19/sublime_debugger
