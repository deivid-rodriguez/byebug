# Byebug

[![Version][gem]][gem_url]
[![Tidelift][tid]][tid_url]
[![Gitter][irc]][irc_url]

[gem]: https://img.shields.io/gem/v/byebug.svg
[tid]: https://tidelift.com/badges/package/rubygems/byebug
[irc]: https://img.shields.io/badge/IRC%20(gitter)-devs%20%26%20users-brightgreen.svg

[gem_url]: https://rubygems.org/gems/byebug
[tid_url]: https://tidelift.com/subscription/pkg/rubygems-byebug?utm_source=rubygems-byebug&utm_medium=readme_badge
[irc_url]: https://gitter.im/deivid-rodriguez/byebug

Byebug is a simple to use and feature rich debugger for Ruby. It uses the
TracePoint API for execution control and the Debug Inspector API for call stack
navigation. Therefore, Byebug doesn't depend on internal core sources. Byebug is also
fast because it is developed as a C extension and reliable because it is supported
by a full test suite.

The debugger permits the ability to understand what is going on _inside_ a Ruby program
while it executes and offers many of the traditional debugging features such as:

* Stepping: Running your program one line at a time.
* Breaking: Pausing the program at some event or specified instruction, to
  examine the current state.
* Evaluating: Basic REPL functionality, although [pry] does a better job at
  that.
* Tracking: Keeping track of the different values of your variables or the
  different lines executed by your program.

## For enterprise

Byebug for enterprise is available via the Tidelift Subscription. [Learn
more][Tidelift for enterprise].

## Build Status

![ubuntu](https://github.com/deivid-rodriguez/byebug/workflows/ubuntu/badge.svg)
![windows](https://github.com/deivid-rodriguez/byebug/workflows/windows/badge.svg)

## Requirements

* _Required_: MRI 3.2.0 or higher.

## Install

```shell
gem install byebug
```

Alternatively, if you use `bundler`:

```shell
bundle add byebug --group "development, test"
```

## Usage

### From within the Ruby code

Simply include `byebug` wherever you want to start debugging and the execution will
stop there. For example, if you were debugging Rails, you would add `byebug` to
your code:

```ruby
def index
  byebug
  @articles = Article.find_recent
end
```

And then start a Rails server:

```shell
bin/rails s
```

Once the execution gets to your `byebug` command, you will receive a debugging prompt.

### From the command line

If you want to debug a Ruby script without editing it, you can invoke byebug from the command line.

```shell
byebug myscript.rb
```

## Byebug's commands

Command     | Aliases         | Subcommands | Description
-------     | -------         | ----------- | -----------
`backtrace` | `bt` `w` `where`| | Displays the backtrace
`break`     | `b`             | | Sets breakpoints in the source code
`catch`     | `cat`           | | Handles exception catchpoints
`condition` | `cond`          | | Sets conditions on breakpoints
`continue`  | `c` `cont`      | | Runs until program ends, hits a breakpoint or reaches a line
`continue!` | `c!` `cont!`    | | Unconditional continue
`debug`     |                 | | Spawns a subdebugger
`delete`    | `del`           | | Deletes breakpoints
`disable`   | `dis`           | `breakpoints` `display` | Disables breakpoints or displays
`display`   | `disp`          | | Evaluates expressions every time the debugger stops
`down`      |                 | | Moves to a lower frame in the stack trace
`edit`      | `ed`            | | Edits source files
`enable`    | `en`            | `breakpoints` `display` | Enables breakpoints or displays
`finish`    | `fin`           | | Runs the program until frame returns
`frame`     | `f`             | | Moves to a frame in the call stack
`help`      | `h`             | | Helps you using byebug
`history`   | `hist`          | | Shows byebug's command history
`info`      | `i`             | `args` `breakpoints` `catch` `display` `file` `line` `program` | Shows information about the program being debugged
`interrupt` | `int`           | | Interrupts the program
`irb`       |                 | | Starts an IRB session
`kill`      |                 | | Sends a signal to the current process
`list`      | `l`             | | Lists lines of source code
`method`    | `m`             | `instance` | Shows methods of an object, class or module
`next`      | `n`             | | Runs one or more lines of code
`pry`       |                 | | Starts a Pry session
`quit`      | `q`             | | Exits byebug
`quit!`     | `q!`            | | Exits byebug unconditionally
`restart`   |                 | | Restarts the debugged program
`save`      | `sa`            | | Saves current byebug session to a file
`set`       |                 | `autoirb` `autolist` `autopry` `autosave` `basename` `callstyle` `fullpath` `histfile` `histsize` `linetrace` `listsize` `post_mortem` `savefile` `stack_on_error` `width` | Modifies byebug settings
`show`      |                 | `autoirb` `autolist` `autopry` `autosave` `basename` `callstyle` `fullpath` `histfile` `histsize` `linetrace` `listsize` `post_mortem` `savefile` `stack_on_error` `width` | Shows byebug settings
`skip`      | `sk`            | | Runs until the next breakpoint as long as it is different from the current one
`source`    | `so`            | | Restores a previously saved byebug session
`step`      | `s`             | | Steps into blocks or methods one or more times
`thread`    | `th`            | `current` `list` `resume` `stop` `switch` | Commands to manipulate threads
`tracevar`  | `tr`            | | Enables tracing of a global variable
`undisplay` | `undisp`        | | Stops displaying all or some expressions when program stops
`untracevar`| `untr`          | | Stops tracing a global variable
`up`        |                 | | Moves to a higher frame in the stack trace
`var`       | `v`             | `all` `constant` `global` `instance` `local` | Shows variables and their values

## Semantic Versioning

Byebug attempts to follow [semantic versioning](https://semver.org) and
bump major version only when backwards incompatible changes are released.
Backwards compatibility is targeted to [pry-byebug] and any other plugins
relying on `byebug`.

## Getting Started

Read [byebug's markdown
guide](https://github.com/deivid-rodriguez/byebug/blob/main/GUIDE.md) to get
started. Proper documentation will be eventually written.

## Related projects

* [pry-byebug] adds `next`, `step`, `finish`, `continue` and `break` commands
  to `pry` using `byebug`.
* [ruby-debug-passenger] adds a rake task that restarts Passenger with Byebug
  connected.
* [minitest-byebug] starts a byebug session on minitest failures.
* [sublime_debugger] provides a plugin for ruby debugging on Sublime Text.
* [atom-byebug] provides integration with the Atom editor [EXPERIMENTAL].

## Contribute

See [Getting Started with Development](CONTRIBUTING.md).

## Funding

Subscribe to [Tidelift][Tidelift support] to ensure byebug stays actively
maintained, and at the same time get licensing assurances and timely security
notifications for your open source dependencies.

You can also help `byebug` by leaving a small (or big) tip through [Liberapay].

## Security contact information

Please use the Tidelift security contact to [report a security vulnerability].
Tidelift will coordinate the fix and disclosure.

## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, especially:

* @ko1, author of the awesome TracePoint API for Ruby.
* @cldwalker, [debugger]'s maintainer.
* @denofevil, author of [debase], the starting point of this.
* @kevjames3 for testing, bug reports and the interest in the project.
* @FooBarWidget for working and helping with remote debugging.

[debugger]: https://github.com/cldwalker/debugger
[pry]: https://github.com/pry/pry
[debase]: https://github.com/denofevil/debase
[pry-byebug]: https://github.com/deivid-rodriguez/pry-byebug
[ruby-debug-passenger]: https://github.com/davejamesmiller/ruby-debug-passenger
[minitest-byebug]: https://github.com/kaspth/minitest-byebug
[sublime_debugger]: https://github.com/shuky19/sublime_debugger
[atom-byebug]: https://github.com/izaera/atom-byebug
[Liberapay]: https://liberapay.com/byebug/donate
[Tidelift]: https://tidelift.com/subscription/pkg/rubygems-byebug?utm_source=rubygems-byebug&utm_medium=readme_text
[Tidelift for enterprise]: https://tidelift.com/subscription/pkg/rubygems-byebug?utm_source=rubygems-byebug&utm_medium=referral&utm_campaign=github&utm_content=enterprise
[Tidelift support]: https://tidelift.com/subscription/pkg/rubygems-byebug?utm_source=rubygems-byebug&utm_medium=referral&utm_campaign=github&utm_content=support
[report a security vulnerability]: https://tidelift.com/security
