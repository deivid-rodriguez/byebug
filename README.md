# Byebug [![Gem Version][1]][2] [![Build Status][3]][4] [![Code Climate][5]][6] [![Dependency Status][7]][8]

<img src="https://raw.github.com/deivid-rodriguez/byebug/master/logo.png"
     alt="Byebug logo" align="right" style="margin-left: 10px" />

_Debugging in Ruby 2.0_

Byebug is a simple to use, feature rich debugger for Ruby 2.0. It uses the new
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

**Please upgrade your ruby to 2.0.0-p247 or higher** - a bug in ruby core was
directly affecting byebug and a fix for it has been released with this
patchlevel (see [#5](https://github.com/deivid-rodriguez/byebug/issues/5) for
more information)


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
* Stopping execution using the word `debugger` doesn't work anymore unless you
explicitly alias it. Similarly, the startup configuration file is now called
`.byebugrc` instead of `.rdebugrc`.
* `autoreload`, `autoeval` and `autolist` are default options in Byebug so you
no longer need to set them in the startup file.


## What's different from debugger

* Works on 2.0.0 and it doesn't on 1.9.x.
* Has no MRI internal source code dependencies, just a clean API.
* Fixes all of debugger's open bugs in its issue tracker and provides some
enhancements, such as a markdown guide or the fact that `byebug` can now be
placed at the end of a block or method call.
* Very actively mantained.
* Editor agnostic: no external editor built-in support.
* Pry command is built-in. No need of external gem like debugger-pry.


## Semantic Versioning

Byebug tries to follow [semantic versioning](http://semver.org). Backwards
compatibility doesn't seem like a critic issue for a debugger because it's not
supposed to be used permanently by any program, let alone in production
environments. However, I still like the idea of giving some meaning to version
changes.

Byebug's public API is determined by its set of commands

    Command   | Aliases  | Subcommands
    ----------|----------|------------------------------------------------------
    backtrace | bt,where |
    break     |          |
    catch     |          |
    condition |          |
    continue  |          |
    delete    |          |
    disable   |          | breakpoints,display
    display   |          |
    down      |          |
    edit      |          |
    enable    |          | breakpoints,display
    finish    |          |
    frame     |          |
    help      |          |
    info      |          | args,breakpoints,catch,display,file,files,...
    irb       |          |
    kill      |          |
    list      |          |
    method    |          | instance,iv
    next      |          |
    p         | eval     |
    pp        |          |
    pry       |          |
    ps        |          |
    putl      |          |
    quit      | exit     |
    reload    |          |
    restart   |          |
    save      |          |
    set       |          | args,autoeval,autoirb,autolist,autoreload,basename...
    show      |          | args,autoeval,autoirb,autolist,autoreload,basename...
    skip      |          |
    source    |          |
    step      |          |
    thread    |          | current,list,resume,stop,switch
    trace     |          |
    undisplay |          |
    up        |          |
    var       |          | class,constant,global,instance,local,ct

Full lists of subcommands:

* info: `args`,`breakpoints`,`catch`,`display`,`file`,`files`,
`global_variables`,`instance_variables`,`line`,`locals`,`program,stack`,
`variables`.
* set: `args`,`autoeval`,`autoirb`,`autolist`,`autoreload`,`basename`,
`callstyle`,`forcestep`,`fullpath`,`history`,`linetrace`,`linetrace_plus`,
`listsize`,`post_mortem`,`stack_on_error`,`testing`,`verbose`,`width`.
* show: `args`,`autoeval`,`autoirb`,`autolist`,`autoreload`,`basename`,
`callstyle`,`commands`,`forcestep`,`fullpath`,`history`,`linetrace`,
`linetrace_plus`, `listsize`,`post_mortem`,`stack_on_error`,`verbose`, `width`.


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


## Future (possible) directions

* JRuby support.
* Libify and test byebug's executable.


## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* Kent Sibilev and Mark Moseley, original authors of
[ruby-debug](https://github.com/mark-moseley/ruby-debug).
* Gabriel Horner, [debugger](https://github.com/cldwalker/debugger)'s mantainer.
* Koichi Sasada, author of the new C debugging API for Ruby.
* Dennis Ushakov, author of [debase](https://github.com/denofevil/debase), the
starting point of this.
* Logo by [Ivlichev Victor Petrovich](http://www.aha-soft.com/)
* @kevjames3 for testing, bug reports and the interest in the project.

[1]: https://badge.fury.io/rb/byebug.png
[2]: http://badge.fury.io/rb/byebug
[3]: https://secure.travis-ci.org/deivid-rodriguez/byebug.png
[4]: http://travis-ci.org/deivid-rodriguez/byebug
[5]: https://codeclimate.com/github/deivid-rodriguez/byebug.png
[6]: https://codeclimate.com/github/deivid-rodriguez/byebug
[7]: https://gemnasium.com/deivid-rodriguez/byebug.png
[8]: https://gemnasium.com/deivid-rodriguez/byebug
