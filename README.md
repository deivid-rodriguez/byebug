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

## Getting Started

### Summary

The purpose of a debugger such as *byebug* is to allow you to see what is going
on _inside_ a Ruby program while it executes. `byebug` can do four main kinds of
things (plus other things in support of these) to help you catch bugs in the
act:

* Start your script, specifying anything that might affect its behavior.
* Make your script stop on specified conditions.
* Examine what has happened, when your script has stopped.
* Change things in your script, so you can experiment with correcting the
effects of one bug and go on to learn about another.

Although you can use `byebug` to invoke your Ruby programs via a debugger at the
outset, there are other ways to use and enter the debugger.

### First Sample Session

A handful of commands are enough to get started using `byebug`. The following
session illustrates these commands. Below is Ruby code to compute a triangle
number of a given length (there are shorter ways to do it, of course).

```
$ byebug triangle.rb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
   1    #!/usr/bin/env ruby
   2    # Compute the n\'th triangle number - the hard way
   3    # triangle(n) == (n * (n+1)) / 2
=> 4    def triangle(n)
   5      tri = 0
   6      0.upto(n) do |i|
   7        tri += i
   8      end
   9      tri
   10   end
(byebug)
```

We are currently stopped before the first executable line of the program: line 4
of `triangle.rb`. If you are used to less dynamic languages and have used
debuggers for more statically compiled languages like C, C++, or Java, it may
seem odd to be stopped before a function definition but in Ruby line 4 is
executed.

byebug's prompt is `(byebug)`. If the program has died and you are in
post-mortem debugging, `(byebug:post-mortem)` is used instead. If the program
has terminated normally, the string this position will be `(byebug:ctrl)`. The
commands available change depending on the program's state.

Byebug automatically lists 10 lines of code centered around the current line
everytime it is stopped. The current line is marked with `=>`, so the range
byebug would like to show is [-1..8]. However since there aren't 5 lines before
the current line, the range is moved ``up'' so we can actually display 10 lines
of code.

Now let us step through the program.

```
(byebug) step
[4, 13] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
   4    def triangle(n)
   5      tri = 0
   6      0.upto(n) do |i|
   7        tri += i
   8      end
   9      tri
   10   end
   11
=> 12   t = triangle(3)
   13   puts t
(byebug) <RET> # hit enter
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
   1    #!/usr/bin/env ruby
   2    # Compute the n'th triangle number - the hard way
   3    # triangle(n) == (n * (n+1)) / 2
   4    def triangle(n)
=> 5      tri = 0
   6      0.upto(n) do |i|
   7        tri += i
   8      end
   9      tri
   10   end
(byebug) p tri
nil
(byebug) step
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
   1    #!/usr/bin/env ruby
   2    # Compute the n'th triangle number - the hard way
   3    # triangle(n) == (n * (n+1)) / 2
   4    def triangle(n)
   5      tri = 0
=> 6      0.upto(n) do |i|
   7        tri += i
   8      end
   9      tri
   10   end
(byebug) p tri
0
```

The first `step` command runs the script one executable unit. The second command
we entered was just hitting the return key; `byebug` remembers the last command
you entered was `step` and it runs it again.

One way to print the values of variables is `p` (there are other ways). When we
look at the value of `tri` the first time, we see it is `nil`. Again we are
stopped _before_ the assignment on line 5, and this variable hasn't been set
previously. However after issuing another `step` command we see that the value
is 0 as expected. If every time we stop we want to see the value of `tri` to see
how things are going, there is a better way by setting a display expression:

```
(byebug:1) display tri
1: tri = 0
```

Now let us run the program until we return from the function. We'll want to see
which lines get run.

```
(byebug) display i
2: i =
(byebug) set linetrace on
line tracing is on.
(byebug) finish
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:7 tri += i
1: tri = 0
2: i = 0
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:7 tri += i
1: tri = 0
2: i = 1
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:7 tri += i
1: tri = 1
2: i = 2
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:7 tri += i
1: tri = 3
2: i = 3
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:9 tri
1: tri = 6
2: i =
Tracing: /home/davidr/Proyectos/byebug/old_doc/triangle.rb:13 puts t
1: tri =
2: i =
[4, 13] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
   4    def triangle(n)
   5      tri = 0
   6      0.upto(n) do |i|
   7        tri += i
   8      end
   9      tri
   10   end
   11
   12   t = triangle(3)
=> 13   puts t
1: tri =
2: i =
(byebug) quit
Really quit? (y/n) y
```

So far, so good. As you can see from the above to get out of `byebug`, one
can issue a `quit` command (`q` and `exit` are just as good). If you want to
quit without being prompted, suffix the command with an exclamation mark, e.g.,
`q!`.

### The rest of the tutorial is available [here]()

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
