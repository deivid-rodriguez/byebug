# Byebug [![Gem Version][1]][2] [![Build Status][3]][4] [![Code Climate][5]][6] [![Dependency Status][7]][8]

<img src="https://raw.github.com/deivid-rodriguez/byebug/master/logo.png"
     alt="Byebug logo" align="right" style="margin-left: 10px" />

_Debugging in Ruby 2.0_

Byebug is a simple to use, feature rich debugger for Ruby 2.0. It uses the new
TracePoint API for execution control and the new Debug Inspector API for call
stack navigation, so it doesn't depend on internal core sources. It's developed
as a C extension, so it's fast. And it has a full test suite so it's (I hope)
reliable.

It allows you to see what is going on _inside_ a Ruby program while it executes
and can do four main kinds of things (plus other things in support of these) to
help you catch bugs in the act:

* Start your program or attach to it, specifying anything that might affect its
behavior.
* Make your program stop on specified conditions.
* Examine what has happened when your program has stopped.
* Change things in your program, so you can experiment with correcting the
effects of one bug and go on to learn about another.


## Install

Just drop

    gem 'byebug'

in your Gemfile and run

    bundle install


## Usage

Simply drop

    byebug

wherever you want to start debugging and the execution will stop there. If you
are debugging rails, start the server in normal mode with `rails server` and
once the execution get to your `byebug` command you will get a debugging
terminal.

_If you are coming from debugger, notice that stopping execution using the word
 `debugger` doesn't work anymore unless you explicitly alias it._

### Configuration

You can automatically load some configurations at startup by dropping them in
the startup file `.byebugrc`. For example, you can change the number of lines
listed whenever byebug stops like this:

    set listsize 20

If you are coming from [debugger](https://github.com/cldwalker/debugger), notice
however that you no longer need

    set autoreload

because it is a default option in byebug.


## What's different from debugger

* Works on 2.0.0 and it doesn't on 1.9.x.
* Has no MRI internal source code dependencies, just a clean API.
* Fixes most of debugger's current open issues:
  - Post mortem mode segfaulting.
  - Line number wrongly shown as zero in backtrace.
  - Line tracing.
  - Colon delimited include paths.
  - Nice markdow guide.
  - Ruby 2.0 support.
* Very actively mantained.
* Editor agnostic: no external editor built-in support.
* No thread support as not supported by the new API yet (I hope it will come
  soon!).
* Pry command is built-in. No need of external gem like debugger-pry.


## Getting Started

A handful of commands are enough to get started using `byebug`. The following
session illustrates these commands. Below is Ruby code to compute a triangle
number of a given length (there are shorter ways to do it, of course).

```
$ byebug triangle.rb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    1: # Compute the n'th triangle number: triangle(n) == (n*(n+1))/2
=>  2: def triangle(n)
    3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: t = triangle(3)
(byebug)
```

We are currently stopped before the first executable line of the program: line 2
of `triangle.rb`. If you are used to less dynamic languages and have used
debuggers for more statically compiled languages like C, C++, or Java, it may
seem odd to be stopped before a function definition but in Ruby line 2 is
executed.

Byebug's prompt is `(byebug)`. If the program has died and you are in
post-mortem debugging, `(byebug:post-mortem)` is used instead. If the program
has terminated normally, the string this position will be `(byebug:ctrl)`. The
commands available change depending on the program's state.

Byebug automatically lists 10 lines of code centered around the current line
everytime it is stopped. The current line is marked with `=>`, so the range
byebug would like to show is [-3..6]. However since there aren't 5 lines before
the current line, the range is moved _up_ so we can actually display 10 lines
of code.

Now let us step through the program.

```
(byebug) step
[2, 11] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    2: def triangle(n)
    3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
=> 10: t = triangle(3)
   11: puts t
(byebug) <RET> # hit enter
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    1: # Compute the n'th triangle number: triangle(n) == (n*(n+1))/2
    2: def triangle(n)
=>  3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: t = triangle(3)
(byebug) p tri
nil
(byebug) step
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    1: # Compute the n'th triangle number: triangle(n) == (n*(n+1))/2
    2: def triangle(n)
    3:   tri = 0
=>  4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: t = triangle(3)
(byebug) p tri
0
```

The first `step` command runs the script one executable unit. The second command
we entered was just hitting the return key; `byebug` remembers the last command
you entered was `step` and it runs it again.

One way to print the values of variables is `p` (there are other ways). When we
look at the value of `tri` the first time, we see it is `nil`. Again we are
stopped _before_ the assignment on line 3, and this variable hasn't been set
previously. However after issuing another `step` command we see that the value
is 0 as expected. If every time we stop we want to see the value of `tri` to see
how things are going, there is a better way by setting a display expression:

```
(byebug) display tri
1: tri = 0
```

Now let us run the program until we return from the function. We'll want to see
which lines get run, so we turn on _line tracing_. If we don't want whole paths
to be displayed when tracing, we can turn on _basename_.

```
(byebug) display i
2: i =
(byebug) set linetrace on
line tracing is on.
(byebug) set basename on
basename is on.
(byebug) finish
Tracing: triangle.rb:5 tri += i
1: tri = 0
2: i = 0
Tracing: triangle.rb:5 tri += i
1: tri = 0
2: i = 1
Tracing: triangle.rb:5 tri += i
1: tri = 1
2: i = 2
Tracing: triangle.rb:5 tri += i
1: tri = 3
2: i = 3
Tracing: triangle.rb:7 tri
1: tri = 6
2: i =
Tracing: triangle.rb:11 puts t
1: tri =
2: i =
[2, 11] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    2: def triangle(n)
    3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: t = triangle(3)
=> 11: puts t
1: tri =
2: i =
(byebug) quit
Really quit? (y/n) y
```

So far, so good. As you can see from the above to get out of `byebug`, one
can issue a `quit` command (`q` and `exit` are just as good). If you want to
quit without being prompted, suffix the command with an exclamation mark, e.g.,
`q!`.

### The rest of the tutorial is available [here](https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md)


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
* Logo by [Ivlichev Victor Petrovich](http://www.aha-soft.com/)

[1]: https://badge.fury.io/rb/byebug.png
[2]: http://badge.fury.io/rb/byebug
[3]: https://secure.travis-ci.org/deivid-rodriguez/byebug.png
[4]: http://travis-ci.org/deivid-rodriguez/byebug
[5]: https://codeclimate.com/github/deivid-rodriguez/byebug.png
[6]: https://codeclimate.com/github/deivid-rodriguez/byebug
[7]: https://gemnasium.com/deivid-rodriguez/byebug.png
[8]: https://gemnasium.com/deivid-rodriguez/byebug
