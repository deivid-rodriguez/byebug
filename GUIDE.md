### First Steps

A handful of commands are enough to get started using `byebug`. The following
session illustrates these commands.

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


### Second Sample Session: Delving Deeper

In this section we'll introduce breakpoints, the call stack and restarting.
Below we will debug a simple Ruby program to solve the classic Towers of Hanoi
puzzle. It is augmented by the bane of programming: some command-parameter
processing with error checking.

```bash
$ byebug hanoi.rb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
=>  2: def hanoi(n,a,b,c)
    3:   if n-1 > 0
    4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
(byebug)
```

Recall in the first section iwe said that before the `def` is run, the method it
names is undefined. Let's check that out. First let's see what private methods
we can call before running `def hanoi`.

```bash
(byebug) private_methods
[:public, :private, :include, :using, :define_method, :default_src_encoding, ...
```

`private_methods` is not a byebug command but a Ruby feature. By default, when
byebug doesn't understand a command, it will evaluate it as if it was a Ruby
command. If you don't want this behaviour, you can use `set autoeval off` or
even drop it in your `.byebugrc` file if you want that behaviour permanently.
The output of `private_methods`, thought, is unwieldy for our porpuse: check
whether `hanoi` method is in the list. Fortunately, byebug has nice formatting
features: we can sort the output and put it into columns list using the print
command `ps`.

```bash
(byebug) ps private_methods
Array             debug_program         open                        sprintf    
Complex           default_src_encoding  p                           srand      
DelegateClass     define_method         pp                          syscall    
Digest            eval                  print                       system     
Float             exec                  printf                      test       
Hash              exit                  private                     throw      
Integer           exit!                 proc                        trace_var  
Pathname          fail                  process_options             trap       
Rational          fork                  public                      untrace_var
String            format                putc                        using      
__callee__        gem                   puts                        warn       
__dir__           gem_original_require  raise                       whence_file
__method__        gets                  rand                      
`                 global_variables      readline                  
abort             include               readlines                 
at_exit           initialize            require                   
autoload          initialize_clone      require_relative          
autoload?         initialize_copy       respond_to_missing?       
binding           initialize_dup        select                    
block_given?      iterator?             set_trace_func            
caller            lambda                singleton_method_added    
caller_locations  load                  singleton_method_removed  
catch             local_variables       singleton_method_undefined
dbg_print         loop                  sleep                     
dbg_puts          method_missing        spawn                     
(byebug)
```

Now let's see what happens after stepping:

```bash
(byebug) private_methods.member?(:hanoi)
false
(byebug:1) step
[7, 16] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
   11:
=> 12: i_args=ARGV.length
   13: if i_args > 1
   14:   puts "*** Need number of disks or no parameter"
   15:   exit 1
   16: end
(byebug) private_methods.member?(:hanoi)
true
(byebug)
```

Okay, lets go on and talk about program arguments.

```bash
(byebug) ARGV
[]
```

Ooops. We forgot to specify any parameters to this program. Let's try again. We
can use the `restart` command here.

```bash
(byebug) restart 3
Re exec'ing:
  /home/davidr/.rvm/gems/ruby-2.0.0-p195@byebug/gems/byebug-1.1.1/bin/byebug /home/davidr/Proyectos/byebug/old_doc/hanoi.rb 3
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
=>  2: def hanoi(n,a,b,c)
    3:   if n-1 > 0
    4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
(byebug) break 4
Created breakpoint 1 at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:3
(byebug) continue
Stopped by breakpoint 1 at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:3
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
    2: def hanoi(n,a,b,c)
=>  3:   if n-1 > 0
    4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
(byebug) display n
1: n = 3
(byebug) display a
2: a = a
(byebug) undisplay 2
(byebug) display a.inspect
3: a.inspect = :a
(byebug) display b.inspect
4: b.inspect = :b
(byebug) continue
Stopped by breakpoint 1 at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:3
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
    2: def hanoi(n,a,b,c)
=>  3:   if n-1 > 0
    4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
1: n = 2
3: a.inspect = :a
4: b.inspect = :c
(byebug) c
Stopped by breakpoint 1 at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:3
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
    2: def hanoi(n,a,b,c)
=>  3:   if n-1 > 0
    4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
1: n = 1
3: a.inspect = :a
4: b.inspect = :b
(byebug) set nofullpath
Displaying frame's full file names is off.
(byebug) where
--> #0  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol) at .../byebug/old_doc/hanoi.rb:4
    #1  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol) at .../byebug/old_doc/hanoi.rb:8
    #2  <top (required)> at .../byebug/old_doc/hanoi.rb:34
(byebug)
```

In the above we added new commands: `break` (see [breakpoints]()), which
indicates to stop just before that line of code is run, and `continue`, which
resumes execution.  Notice the difference between `display a` and 
`display a.inspect`. An implied string conversion is performed on the expression
after it is evaluated. To remove a display expression `undisplay` is used. If we
give a display number, just that display expression is removed.

We also used a new command `where`(see [backtrace]()) to show the callstack. In
the above situation, starting from the bottom line we see we called the `hanoi`
method from line 34 of the file `hanoi.rb` and the `hanoi` method called itself
two more times at line 4.

In the callstack we show a _current frame_ mark, the frame number, the method
being called, the names of the parameters, the types those parameters
_currently_ have and the file-line position. Remember it's possible that when
the program was called the parameters had different types, since the types of
variables can change dynamically. You can alter the style of what to show in the
trace (see [callstyle]()).

Now let's move around the callstack.

```bash
(byebug) undisplay
Clear all expressions? (y/n) y
(byebug) i_args
NameError Exception: undefined local variable or method `i_args' for main:Object
(byebug) frame -1
[25, 34] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
   25:     exit 2
   26:   end
   27: end
   28:
   29: if n < 1 or n > 100
   30:   puts "*** number of disks should be between 1 and 100"
   31:   exit 2
   32: end
   33:
=> 34: hanoi(n, :a, :b, :c)
(byebug) i_args
0
(byebug) p n
3
(byebug) down 2
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/hanoi.rb
    1: # Solves the classic Towers of Hanoi puzzle.
    2: def hanoi(n,a,b,c)
    3:   if n-1 > 0
=>  4:     hanoi(n-1, a, c, b)
    5:   end
    6:   puts "Move disk %s to %s" % [a, b]
    7:   if n-1 > 0
    8:     hanoi(n-1, c, b, a)
    9:   end
   10: end
(byebug:1) p n
2
```

Notice in the above to get the value of variable `n` we had to use a print
command like `p n`. If we entered just `n`, that would be taken to mean byebug
command `next`. In the current scope, variable `i_args` is not defined.
However I can change to the top-most frame by using the `frame` command. Just as
with arrays, -1 means the last one. Alternatively using frame number 3 would
have been the same thing; so would issuing `up 3`. Note that in the outside
frame #3, the value of `i_args` can be shown. Also note that the value of
variable `n` is different.


### Attaching to a running program with `byebug`

In the previous sessions we've been calling byebug right at the outset, but
there is another mode of operation you might use. If there's a lot of code that
needs to be run before the part you want to inspect, it might not be efficient
or convenient to run byebug from the outset.

In this section we'll show how to enter the code in the middle of your program,
while delving more into byebug's operation. We will also use unit testing. Using
unit tests will greatly reduce the amount of debugging needed, while at the same
time, will increase the quality of your program.

What we'll do is take the `triangle` code from the first session and write a
unit test for that. In a sense we did write a tiny test for the program which
was basically the last line where we printed the value of `triangle(3)`. This
test however wasn't automated: the expectation is that someone would look at the
output and verify that what was printed is what was expected.

Before we can turn that into something that can be `required`, we probably want
to remove that output. However I like to keep in that line so that when I
look at the file, I have an example of how to run it.  Therefore we will
conditionally run this line if that file is invoked directly, but skip it if it
is not. _NOTE: `byebug` resets `$0` to try to make things like this work._

```ruby
if __FILE__ == $0
  t = triangle(3)
  puts t
end
```

Okay, we're now ready to write our unit test. We'll use `minitest` which comes
with the standard Ruby distribution.  Here's the test code; it should be in the
same directory as `triangle.rb`.

```ruby
require 'minitest/autorun'
require_relative 'triangle.rb'

class TestTri < MiniTest::Unit::TestCase
  def test_basic
    solutions = []
    0.upto(5) do |i|
      solutions << triangle(i)
    end
    assert_equal([0, 1, 3, 6, 10, 15], solutions,
                 'Testing the first 5 triangle numbers')
  end
end
```

Let's say we want to stop before the first statement in our test method, we'll
add the following:

```ruby
...
def test_basic
  byebug
  solutions = []
...
```

Now we run the program, requiring `byebug`

```bash
$ ruby -rbyebug test-triangle.rb
Run options: --seed 13073

# Running tests:

[2, 11] in test-triangle.rb
    2: require_relative 'triangle.rb'
    3: 
    4: class TestTri < MiniTest::Unit::TestCase
    5:   def test_basic
    6:     byebug
=>  7:     solutions = []
    8:     0.upto(5) do |i|
    9:       solutions << triangle(i)
   10:     end
   11:     assert_equal([0, 1, 3, 6, 10, 15], solutions,
(byebug)
```

and we see that we are stopped at line 7 just before the initialization of the
list `solutions`.

Now let's see where we are...

```bash
(byebug) set nofullpath
Displaying frame's full file names is off.
(byebug) bt
--> #0  TestTri.test_basic at test-triangle.rb:7
    #1  MiniTest::Unit::TestCase.run(runner#MiniTest::Unit) at .../2.0.0/minitest/unit.rb:1301
    #2  MiniTest::Unit.block in _run_suite(suite#Class, type#Symbol) at .../2.0.0/minitest/unit.rb:919
     +-- #3  Array.map at .../2.0.0/minitest/unit.rb:912
    #4  MiniTest::Unit._run_suite(suite#Class, type#Symbol) at .../2.0.0/minitest/unit.rb:912
    #5  MiniTest::Unit.block in _run_suites(suites#Array, type#Symbol) at .../2.0.0/minitest/unit.rb:899
     +-- #6  Array.map at .../2.0.0/minitest/unit.rb:899
    #7  MiniTest::Unit._run_suites(suites#Array, type#Symbol) at .../2.0.0/minitest/unit.rb:899
    #8  MiniTest::Unit._run_anything(type#Symbol) at .../2.0.0/minitest/unit.rb:867
    #9  MiniTest::Unit.run_tests at .../2.0.0/minitest/unit.rb:1060
    #10 MiniTest::Unit.block in _run(args#Array) at .../2.0.0/minitest/unit.rb:1047
     +-- #11 Array.each at .../2.0.0/minitest/unit.rb:1046
    #12 MiniTest::Unit._run(args#Array) at .../2.0.0/minitest/unit.rb:1046
    #13 MiniTest::Unit.run(args#Array) at .../2.0.0/minitest/unit.rb:1035
    #14 #<Class:MiniTest::Unit>.block in autorun at .../2.0.0/minitest/unit.rb:789
(byebug)
```

We get the same result as if we had run byebug from the outset, just faster!

__NOTICE: In ruby-debug, debugger and older versions of byebug, this would not
work as expected. If you are having issues, please upgrade to byebug >= 1.5.0__


### Byebug.start with a block

We saw that `Byebug.start()` and `Byebug.stop()` allow fine-grain control over
where byebug tracking should occur.

Rather than use an explicit `stop()`, you can also pass a block to the `start()`
method. This causes `start()` to run and then `yield` to that block. When the
block is finished, `stop()` is run. In other words, this wraps a
`Byebug.start()` and `Byebug.stop()` around the block of code. But it also has a
side benefit of ensuring that in the presence of an uncaught exception `stop` is
run, without having to explicitly use `begin ... ensure Byebug.stop() end`.

For example, in Ruby on Rails you might want to debug code in one of the
controllers without causing any slowdown to any other code. And this can be done
by wrapping the controller in a `start()` with a block; when the method wrapped
this way finishes, byebug is turned off and the application proceeds at regular
speed.

Of course, inside the block you will probably want to enter the byebug using
`Byebug.byebug()`, otherwise there would be little point in using the `start`.
For example, you can do this in `irb`:

```bash
$ irb
2.0.0p195 :001 > require 'byebug'
 => true
2.0.0p195 :002 > def foo
2.0.0p195 :003?>   x=1
2.0.0p195 :004?>   puts 'foo'
2.0.0p195 :005?>   end
 => nil
2.0.0p195 :006 > Byebug.start{byebug; foo}
(irb) @ 6
(byebug) s
(irb) @ 3
(byebug) s
(irb) @ 4
(byebug) p x
1
(byebug) s
foo
 => true
2.0.0p195 :007 >
```

There is a counter inside of `Byebug.start` method to make sure that this works
when another `Byebug.start` method is called inside of the outer one. However,
if you are stopped inside byebug, issuing another `byebug` call will not have
any effect even if it is nested inside another `Byebug.start`.


### Debugging Oddities: How debugging Ruby may be different from other languages

If you are used to debugging in other languages like C, C++, Perl, Java or even
Bash (see [bashdb](http://bashdb.sf.net)), there may be a number of things that
seem or feel a little bit different and may confuse you. A number of these
things aren't oddities of the debugger per se but differences in how Ruby works
compared to those other languages. Because Ruby works a little differently from
those other languages, writing a debugger has to also be a little different as
well if it is to be useful. In this respect, using byebug may help you
understand Ruby better.

We've already seen one such difference: the fact that we stop on method
definitions or `def`'s and that is because these are in fact executable
statements. In other compiled languages this would not happen because that's
already been done when you compile the program (or in Perl when it scans in the
program). In this section we'll consider some other things that might throw off
new users to Ruby who are familiar with other languages and debugging in them.

* Bouncing Around in Blocks (iterators)
* No Parameter Values in a Call Stack
* Lines You Can Stop At

#### Bouncing Around in Blocks (iterators)

When debugging languages with coroutines like Python and Ruby, a method call may
not necessarily go to the first statement after the method header. It's possible
that the call will continue after a `yield` statement from a prior call.

```ruby
# Enumerator for primes
class SievePrime
  @@odd_primes = []
  def self.next_prime(&block)
    candidate = 2
    yield candidate
    not_prime = false
    candidate += 1
    while true do
      @@odd_primes.each do |p|
        not_prime = (0 == (candidate % p))
        break if not_prime
      end
      unless not_prime
        @@odd_primes << candidate
        yield candidate
      end
      candidate += 2
    end
  end
end
SievePrime.next_prime do |prime|
  puts prime
  break if prime > 10
end
```

```bash
$ byebug primes.rb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/primes.rb
    1: # Enumerator for primes
=>  2: class SievePrime
    3:   @@odd_primes = []
    4:   def self.next_prime(&block)
    5:     candidate = 2
    6:     yield candidate
    7:     not_prime = false
    8:     candidate += 1
    9:     while true do
   10:       @@odd_primes.each do |p|
(byebug) set linetrace
line tracing is on.
(byebug) set basename
basename in on.
(byebug) step 9
Tracing: primes.rb:3 @@odd_primes = []
Tracing: primes.rb:4 def self.next_prime(&block)
Tracing: primes.rb:22 SievePrime.next_prime do |prime|
Tracing: primes.rb:5 candidate = 2
Tracing: primes.rb:6 yield candidate
Tracing: primes.rb:23 puts prime
2
Tracing: primes.rb:24 break if prime > 10
Tracing: primes.rb:7 not_prime = false
Tracing: primes.rb:8 candidate += 1
[3, 12] in /home/davidr/Proyectos/byebug/old_doc/primes.rb
    3:   @@odd_primes = []
    4:   def self.next_prime(&block)
    5:     candidate = 2
    6:     yield candidate
    7:     not_prime = false
=>  8:     candidate += 1
    9:     while true do
   10:       @@odd_primes.each do |p|
   11:         not_prime = (0 == (candidate % p))
   12:         break if not_prime
(byebug)
```

The loop between lines 23-26 gets interleaved between those of
`Sieve::next_prime`, lines 6-19 above.


#### No Parameter Values in a Call Stack

In traditional debuggers, in a call stack you can generally see the names of the
parameters and the values that were passed in.

Ruby is a very dynamic language and it tries to be efficient within the confines
of the language definition. Values generally aren't taken out of a variable or
expression and pushed onto a stack. Instead a new scope is created and the
parameters are given initial values. Parameter passing is by _reference_ not by
_value_ as it is say Algol, C, or Perl. During the execution of a method,
parameter values can change (and often do). In fact even the _class_ of the
object can change.

So at present, the name of the parameter is shown. The call-style setting
([callstyle]()) can be used to set whether the name is shown or the name and the
_current_ class of the object. It has been contemplated that a style might be
added which saves on call shorter "scalar" types of values and the class name.


#### Lines You Can Stop At

As with the duplicate stops per control (e.g. `if` statement), until tools like
debuggers get more traction among core ruby developers there are going to be
weirdness. Here we describe the stopping locations which effects the breakpoint
line numbers you can stop at.

Consider the following little Ruby program.

```ruby
'Yes it does' =~ /
(Yes) \s+
it  \s+
does
/ix
puts $1
```

The stopping points that Ruby records are the last two lines, lines 5 and 6.

Inside `byebug` you can get a list of stoppable lines for a file using the `info
file` command with the attribute `breakpoints`.

To be continued...
* more complex example with objects, pretty printing and irb.
* line tracing and non-interactive tracing.
* mixing in Byebug.debug with byebug
* post-mortem debugging and setting up for that


## Getting in & out

### Starting byebug

There is a wrapper script called `byebug` which basically `require`'s the gem
then loads `byebug` before its argument (the program to be debugged) is started.

```bash
byebug [byebug-options] [--] ruby-script ruby-script-arguments
```

If you don't need to pass dash options to your program, which might be confused
with byebug options, then you don't need to add the `--`. To get a brief list of
options and descriptions, use the `--help` option.

```bash
$ byebug --help
byebug 1.6.1
Usage: byebug [options] <script.rb> -- <script.rb parameters>

Options:
 -d, --debug               Set $DEBUG=true
 -I, --include PATH        Add PATH (single or multiple:path:list) to $LOAD_PATH
     --no-quit             Do not quit when script finishes
     --no-stop             Do not stop when script is loaded
     --nx                  Don't run any byebug initialization files
     --post-mortem         Enable post-mortem mode for uncaught exceptions
 -r, --require SCRIPT      Require library before script
     --restart-script FILE Name of the script file to run. Erased after read
     --script FILE         Name of the script file to run
    -x, --trace            Turn on line tracing

Common options:
        --help             Show this message
        --version          Print program version
    -v                     Print version number, then turn on verbose mode
```

Many options appear as a long option name, such as `--help` and a short one
letter option name, such as `-h`. The list of options is detailed below:

* **-h | --help**. It causes `byebug` to print some basic help and exit
* **-v | --version**. It causes `byebug` to print its version number and
exit.
* **-d | --debug**. Set `$DEBUG` to `true`. Compatible with Ruby's.
* **-I | --include <path>**. Add `path` to load path. `path` can be a single
path ar a colon separated path list.
* **--post-mortem**. If your program raises an exception that isn't caught you
can enter byebug for inspection of what went wrong. You may also want to use
this option in conjunction with `--no-stop`. See also [Post-Mortem Debugging]().
* **--no-quit**. Restart `byebug` when your program terminates normally.
* **--no-stop**. Normally `byebug` stops before executing the first statement.
If instead you want it to start running initially and perhaps break it later in
the execution, use this option.
* **--require | -r**. Require the library before executing the script. However,
if the library happened to be `debug`, we'll just ignore the require since we're
already a debugger. This option is compatible with Ruby's.
* **--script <file>**. Script to run before byebug's execution.
* **-x | --trace**. Turn on line tracing. Running `byebug --trace
<rubyscript>.rb` is pretty much like running `ruby -rtracer
<rubyscript>.rb`. If all you want to do however is get a linetrace, `tracer` is
most likely faster than `byebug`

```bash
$ time ruby -rtracer old_doc/gcd.rb 24 31 >/dev/null

real  0m0.066s
user  0m0.048s
sys 0m0.016s

$ time byebug --trace old_doc/gcd.rb 24 31 >/dev/null

real  0m0.660s
user  0m0.588s
sys 0m0.056s
```

### Byebug default options

Byebug has many command-line options,; it seems that some people want to set
them differently from the defaults. For example, some people may want
`--no-quit` to be the default behavior. One could write a wrapper script or set
a shell alias to handle this. But `byebug` has another way to do it. Before
processing command options, if the file `$HOME/.byebugoptrc` is found, it is
loaded. If you want to set the defaults in some other way, you can put Ruby code
here and set variable `options` which is an OpenStruct. For example here's how
you'd set `-no-quit` and a personal message.

```ruby
# This file contains how you want the default options to byebug to be set. Any
# Ruby code can be put here.
#
# byebug # Uncomment if you want to debug byebug!
options.control = false
puts "rocky's byebugrc run"
```

Here are the default values in `options`

```
#<OpenStruct nx=false, quit=true, restart_script=nil, script=nil, stop=true,
             tracing=false, verbose_long=false>
```

### Command Files

A command file is a file of lines that are `byebug` commands. Comments (lines
starting with `#`) may also be included. An empty line in a command file does
nothing; it does not mean to repeat the last command, as it would from the
terminal.

When you start `byebug`, it automatically executes commands from its
_init file_, called `.byebugrc`. During startup, `byebug` does the following:

* __Processes command line options and operands.__ Reads the init file in your
current directory, if any, and then checks your home directory. The home
directory is the directory named in the `$HOME` or `$HOMEPATH` environment
variable. Thus, you can have more than one init file, one generic in your home
directory, and another, specific to the program you are debugging, in the
directory where you invoke `byebug`.

* __Reads command files specified by the `--script` option.__

You can also request the execution of a command file with the `source` command
(see [Source]()).


### Quitting byebug

To exit `byebug`, use the `quit` command (abbreviated `q` and aliased `exit`).
Normally if you are in an interactive session, this command will prompt to ask
if you really want to quit. If you don't want any questions asked, enter
`quit unconditionally` (abbreviated `q!`). Another way to terminate byebug is to
use the `kill` command. This does the more forceful `kill -9`. It can be used in
cases where `quit` doesn't work (I haven't seen those yet).


### Calling byebug from inside your program

Running a program from byebug adds a bit of overhead and slows it down a little.
Furthermore, by necessity, debuggers change the operation of the program they
are debugging. And this can lead to unexpected and unwanted differences. It has
happened so often that the term
[Heisenbugs](http://en.wikipedia.org/wiki/Heisenbug}) was coined to describe the
situation where using a debugger (among other possibilities) changes the
behavior of the program so that the bug doesn't manifest itself anymore.

There is another way to get into byebug which adds no overhead or slowdown until
you reach the point at which you want to start debugging. However here you must
change the script and make an explicit call to byebug. Because byebug isn't
involved before the first call, there is no overhead and the script will run
at the same speed as if there were no byebug.

To enter byebug this way, just drop `byebug` in whichever line you want to start
debugging at. You also have to require byebug somehow. If using bundler, it will
take care of that for you, otherwise you can use the ruby `-r` flag or add
`require 'byebug'` in the line previous to the `byebug` call.

If speed is crucial, you may want to start and stop this around certain sections
of code, using `Byebug.start` and `Byebug.stop`. Alternatively, instead of
issuing an explicit `Byebug.stop` you can add a block to the `Byebug.start` and
debugging is turned on for that block. If the block of code raises an uncaught
exception that would cause the block to terminate, the `stop` will occur.  See
[Byebug.start with a block]().

When `byebug`is run, `.byebugrc` is read.

You may want to enter byebug at several points in the program where there is a
problem you want to investigate. And since `byebug` is just a method call it's
possible to enclose it in a conditional expression, for example

```ruby
byebug if 'bar' == foo and 20 == iter_count
```

### Restarting Byebug

You can restart the program using `restart [program args]`. This is a re-exec -
all byebug state is lost. If command arguments are passed, those are used.
Otherwise program arguments from the last invocation are used.

You won't be able to restart your program in all cases. First, the program
should have been invoked at the outset rather than having been called from
inside your program or invoked as a result of post-mortem handling.

Also, since this relies on the OS `exec` call, this command is available only if
your OS supports `exec`.


## Byebug Command Reference

### Command Syntax
Usually a command is put on a single line. There is no limit on how long it can be.
It starts with a command name, which is followed by arguments whose meaning depends
on the command name. For example, the command `step` accepts an argument which is the
number of times to step, as in `step 5`. You can also use the `step` command with no
arguments. Some commands do not allow any arguments.

Multiple commands can be put on a line by separating each with a semicolon `;`. You
can disable the meaning of a semicolon to separate commands by escaping it with a
backslash.

For example, if you have [autoeval]() set, which is the default, you might want to
enter the following code to compute the 5th Fibonacci number.

```bash
(byebug) fib1=0; fib2=1; 5.times {|temp| temp=fib1; fib1=fib2; fib2 += temp }
0
1
SyntaxError Exception: /home/davidr/Proyectos/sample_app/trace.rb:1: syntax
error, unexpected end-of-input, expecting '}'
 5.times { |temp| temp=fib1
                           ^
nil
1
SyntaxError Exception: /home/davidr/Proyectos/sample_app/trace.rb:1: syntax
error, unexpected tSTRING_DEND, expecting end-of-input
 fib2 += temp }
               ^
nil
(byebug) fib1=0\; fib2=1\; 5.times {|temp| temp=fib1\; fib1=fib2\; fib2 += temp }
5
(byebug) fib2
8
```

You might also consider using the [irb]() or [pry]() commands and then you won't have
to escape semicolons.

A blank line as input (typing just `<RET>`) means to repeat the previous command.

Byebug uses readline, which handles line editing and retrieval of previous commands.
Up arrow, for example, moves to the previous byebug command; down arrow moves to the
next more recent command (provided you are not already at the last command). Command
history is saved in file `.byebug_hist`. A limit is put on the history size. You
can see this with the `show history size` command. See [history]() for history
parameters.

### Command Output
In the command-line interface, when `byebug` is waiting for input it presents a
prompt of the form `(byebug)`. If the program has terminated normally the prompt will
be `(byebug:ctrl)` and in post-mortem debugging it will be
`(byebug:post-mortem)`.

Whenever `byebug` gives an error message such as for an invalid command or an invalid
location position, it will generally preface the message with `***`.

### Command Help

Once inside `byebug` you can always ask it for information on its commands using the
`help` command. You can use `help` (abbreviated `h`) with no arguments to display a
short list of named classes of commands

```bash
(byebug) help
Type "help <command-name>" for help on a specific command

Available commands:
backtrace  delete   enable  help  method  ps       save    step       where
break      disable  eval    info  next    putl     set     trace
catch      display  exit    irb   p       quit     show    undisplay
condition  down     finish  kill  pp      reload   skip    up
continue   edit     frame   list  pry     restart  source  var
```

With a command name as `help` argument, `byebug` displays short information on how to
use that command.

```bash
(byebug) help list
l[ist]    list forward
l[ist] -  list backward
l[ist] =  list current line
l[ist] nn-mm  list given lines
* NOTE - to turn on autolist, use 'set autolist'
(byebug)
```

A number of commands, namely `info`, `set`, `show`, `enable` and `disable`, have many
sub-parameters or _subcommands_. When you ask for help for one of these commands, you
will get help for all of the subcommands that command offers. Sometimes you may want
help only on a subcommand and to do this just follow the command with its subcommand
name. For example, `help info breakpoints`will just give help about the `info
breakpoints` command. Furthermore it will give longer help than the summary
information that appears when you ask for help. You don't need to list the full
subcommand name, just enough of the letters to make that subcommand distinct from
others will do. For example, `help info b` is the same as `help info breakpoints`.

Some examples follow.

```bash
(byebug) help info
info[ subcommand]

Generic command for showing things about the program being debugged.

--
List of "info" subcommands:
--
info args               -- Argument variables of current stack frame
info breakpoints        -- Status of user-settable breakpoints
info catch              -- Exceptions that can be caught in the current stack
frame
info display            -- Expressions to display when program stops
info file               -- Info about a particular file read in
info files              -- File names and timestamps of files read in
info global_variables   -- Global variables
info instance_variables -- Instance variables of the current stack frame
info line               -- Line number and file name of current position in
source file
info locals             -- Local variables of the current stack frame
info program            -- Execution status of the program
info stack              -- Backtrace of the stack
info variables          -- Local and instance variables of the current stack
frame
```

```bash
(byebug) help info breakpoints
Status of user-settable breakpoints.
Without argument, list info about all breakpoints.
With an integer argument, list info on that breakpoint.
```

```bash
(byebug) help info b
Status of user-settable breakpoints.
Without argument, list info about all breakpoints.
With an integer argument, list info on that breakpoint.
```

### Control Commands: quit, restart, source

#### Quit

To exit `byebug`, type `quit` (abbreviated `q` and aliased `exit`). Normally if
you are in an interactive session, this command will prompt you to confirm you
really want to quit. If you don't want any questions asked, enter
`quit unconditionally` (abbreviated `q!`).

#### Restart

To restart the program, use the `restart|r` command. This is a re-exec - all
`byebug` state is lost. If command arguments are passed, those are used.
Otherwise program arguments from the last invocation are used.

You won't be able to restart your program in all cases. First, the program
should have been invoked at the outset rather than having been called from
inside your program or invoked as a result of post-mortem handling.

#### Source

You can run `byebug` commands inside a file, using the command `source <file>`.
The lines in a command file are executed sequentially. They are not printed as
they are executed. If there is an error, execution proceeds to the next command
in the file. For information about command files that get run automatically on
startup see [Command Files]().


### Display Commands: display, undisplay

#### Display

If you find that you want to print the value of an expression frequently (to see
how it changes), you might want to add it to the *automatic display list** so
that `byebug` evaluates it each time your program stops or after a line is
printed if line tracing is enabled. Each expression added to the list is given a
number to identify it; to remove an expression from the list, you specify that
number. The automatic display looks like this:

```bash
(byebug) display n
1: n = 3
```

This display shows item numbers, expressions and their current values. If the
expression is undefined or illegal the expression will be printed but no value
will appear.

```bash
(byebug) display undefined_variable
2: undefined_variable =
(byebug) display 1/0
3: 1/0 =
```

If you use `display` with no argument, `byebug` will display the current values
of the expressions in the list, just as it is done when your program stops.
Using `info display` has the same effect.

#### Undisplay

To remove an item from the list, use `undisplay` followed by the number
identifying the expression you want to remove. `undisplay` does not repeat if
you press `<RET>`after using it (otherwise you would just get the error _No
display number n_)

You can also temporarily disable or enable display expressions, so that the will
not be printed but they won't be forgotten either, so you can toggle them again
later. To do that, use `disable display` or `enable display` followed by the
expression number.


### Print Commands

One way to examine and change data in your script is with the `eval` command
(abbreviated `p`). `byebug` by default evaluates any input that is not
recognized as a command, so in most situations `eval` is not necessary and
`byebug` will work like a REPL. One case where it's necessary could be when
trying to print a variable called `n`. In this case, you have no choice because
typing just `n` will execute `byebug`'s command `next`.

A similar command to `eval|p` is `pp` which tries to pretty print the result.

If the value you want to print is an array, sometimes a columnized list looks
nicer. Use `putl` for that. Notice however that entries are sorted to run down
first rather than across. If the value is not an array `putl` will just call
pretty-print.

Sometimes you may want to print the array not only columnized, but sorted as
well. The list of byebug help commands appears this way, and so does the output
of the `method` commands. Use `ps` for that. If the value is not an array `ps`
will just call pretty-print.

```bash
(byebug) Kernel.instance_methods
[:nil?, :===, :=~, :!~, :eql?, :hash, :<=>, :class, :singleton_class, :clone,
:dup, :taint, :tainted?, :untaint, :untrust, :untrusted?, :trust, :freeze,
:frozen?, :to_s, :inspect, :methods, :singleton_methods, :protected_methods,
:private_methods, :public_methods, :instance_variables, :instance_variable_get,
:instance_variable_set, :instance_variable_defined?, :remove_instance_variable,
:instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, :respond_to?,
:extend, :display, :method, :public_method, :define_singleton_method,
:object_id, :to_enum, :enum_for, :gem, :pretty_inspect, :byebug]
(byebug) p Kernel.instance_methods
[:nil?, :===, :=~, :!~, :eql?, :hash, :<=>, :class, :singleton_class, :clone,
:dup, :taint, :tainted?, :untaint, :untrust, :untrusted?, :trust, :freeze,
:frozen?, :to_s, :inspect, :methods, :singleton_methods, :protected_methods,
:private_methods, :public_methods, :instance_variables, :instance_variable_get,
:instance_variable_set, :instance_variable_defined?, :remove_instance_variable,
:instance_of?, :kind_of?, :is_a?, :tap, :send, :public_send, :respond_to?,
:extend, :display, :method, :public_method, :define_singleton_method,
:object_id, :to_enum, :enum_for, :gem, :pretty_inspect, :byebug]
(byebug) pp Kernel.instance_methods
[:nil?,
 :===,
 :=~,
 :!~,
 :eql?,
 :hash,
 :<=>,
 :class,
 :singleton_class,
 :clone,
 :dup,
 :taint,
 :tainted?,
 :untaint,
 :untrust,
 :untrusted?,
 :trust,
 :freeze,
 :frozen?,
 :to_s,
 :inspect,
 :methods,
 :singleton_methods,
 :protected_methods,
 :private_methods,
 :public_methods,
 :instance_variables,
 :instance_variable_get,
 :instance_variable_set,
 :instance_variable_defined?,
 :remove_instance_variable,
 :instance_of?,
 :kind_of?,
 :is_a?,
 :tap,
 :send,
 :public_send,
 :respond_to?,
 :extend,
 :display,
 :method,
 :public_method,
 :define_singleton_method,
 :object_id,
 :to_enum,
 :enum_for,
 :gem,
 :pretty_inspect,
 :byebug]
(byebug) putl Kernel.instance_methods
nil?  <=>              tainted?    frozen?            private_methods             remove_instance_variable  public_send    define_singleton_method  byebug
===   class            untaint     to_s               public_methods              instance_of?              respond_to?    object_id
=~    singleton_class  untrust     inspect            instance_variables          kind_of?                  extend         to_enum
!~    clone            untrusted?  methods            instance_variable_get       is_a?                     display        enum_for
eql?  dup              trust       singleton_methods  instance_variable_set       tap                       method         gem
hash  taint            freeze      protected_methods  instance_variable_defined?  send                      public_method  pretty_inspect
(byebug) ps Kernel.instance_methods
!~      clone                    extend   instance_of?                kind_of?        private_methods           respond_to?        tap      untrusted?
<=>     define_singleton_method  freeze   instance_variable_defined?  method          protected_methods         send               to_enum
===     display                  frozen?  instance_variable_get       methods         public_method             singleton_class    to_s   
=~      dup                      gem      instance_variable_set       nil?            public_methods            singleton_methods  trust  
byebug  enum_for                 hash     instance_variables          object_id       public_send               taint              untaint
class   eql?                     inspect  is_a?                       pretty_inspect  remove_instance_variable  tainted?           untrust
```

Finally, if you need more advanced functionality from REPL's, you can enter
`irb` or `pry` using `irb` or `pry` commands. The bindings environment will be
set to the current state in the program.  When you leave the repl and go back to
`byebug`'s command prompt we show the file, line and text position of the
program. If you issue a `list` without location information, the default
location used is the current line rather than the current position that may have
got updated via a prior `list` command.

```
$ byebug triangle.rb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    1: # Compute the n'th triangle number, the hard way: triangle(n) == (n*(n+1))/2
=>  2: def triangle(n)
    3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: if __FILE__ == $0
(byebug) irb
2.0.0-p247 :001 > (0..6).inject{|sum, i| sum +=i}
 => 21
2.0.0-p247 :002 > exit
/home/davidr/Proyectos/byebug/old_doc/triangle.rb @ 2
def triangle(n)
(byebug) list # same line range as before going into irb
[1, 10] in /home/davidr/Proyectos/byebug/old_doc/triangle.rb
    1: # Compute the n'th triangle number, the hard way: triangle(n) == (n*(n+1))/2
=>  2: def triangle(n)
    3:   tri = 0
    4:   0.upto(n) do |i|
    5:     tri += i
    6:   end
    7:   tri
    8: end
    9:
   10: if __FILE__ == $0
(byebug)
```

### Printing variables

Byebug can print many different information about variables. Such as
* `var const <object>`. Show the constants of `<object>`. This is basically
listing variables and their values in `<object>.constant`.
* `var instance <object>`. Show the instance variables of `<object>`. This is
basically listing `<object>.instance_variables`.
* `info instance_variables`. Show instance_variables of `self`.
* `info locals`. Show local variables.
* `info globals`. Show global variables.
* `info variables`. Show local and instance variables of `self`.
* `method instance <object>`. Show methods of `<object>`. Basically this is the
same as running `ps <object>.instance_methods(false)`.
* `method iv <object>`. Show method instance variables of `object`. Basically
this is the same as running
```
  <object>.instance_variables.each do |v|
     puts "%s = %s\n" % [v, <object>.instance_variable_get(v)]
  end
```
* `signature <object>`. Show signature of method `<object>`. _This command is
available only if the nodewrap gem is installed_.

```ruby
  def mymethod(a, b=5, &bock)
  end
  (byebug) method sig mymethod
  Mine#mymethod(a, b=5, &bock)
```

* `method <class-or-module>`. Show methods of the class or module
`<class-or-module>`. Basically this is the same as running
`ps <class-or-module>.methods`.

### Examining Program Source Files (`list`)

`byebug` can print parts of your script's source.  When your script stops,
`byebug` spontaneously lists the source code around the line where it stopped
that line. It does that when you change the current stack frame as well.
Implicitly there is a default line location. Each time a list command is run
that implicit location is updated, so that running several list commands in
succession shows a contiguous block of program text.

If you don't need code context displayed every time, you can issue the `set
noautolist` command. Now whenever you want code listed, you can explicitly issue
the `list` command or its abbreviation `l`. Notice that when a second listing is
displayed, we continue listing from the place we last left off. When the
beginning or end of the file is reached, the line range to be shown is adjusted
so "it doesn't overflow". You can set the `noautolist` option by default by
dropping `set noautolist` in byebug's startup file `.byebugrc`.

If you want to set how many lines to be printed by default rather than use the
initial number of lines, 10, use the `set listsize` command ([listsize()). To
see the entire program in one shot, give an explicit starting and ending line
number. You can print other portions of source files by giving explicit position
as a parameter to the list command.

There are several ways to specify what part of the file you want to print. `list
nnn` prints lines centered around line number `nnn` in the current source file.
`l` prints more lines, following the last lines printed. `list -` prints lines
just before the lines last printed. `list nnn-mmm` prints lines between `nnn`
and `mmm` inclusive. `list =` prints lines centered around where the script is
stopped. Repeating a `list` command with `RET` discards the argument, so it is
equivalent to typing just `list`.  This is more useful than listing the same
lines again. An exception is made for an argument of `-`: that argument is
preserved in repetition so that each repetition moves up in the source file.

### Editing Source files (`edit`)

To edit a source file, use the `edit` command.  The editor of your choice is invoked
with the current line set to the active line in the program. Alternatively, you can
give a line specification to specify what part of the file you want to edit.

You can customize `byebug` to use any editor you want by using the `EDITOR`
environment variable. The only restriction is that your editor (say `ex`) recognizes
the following command-line syntax:
```
ex +nnn file
```

The optional numeric value `+nnn` specifies the line number in the file where
you want to start editing. For example, to configure `byebug` to use the `vi` editor,
you could use these commands with the `sh` shell:

```bash
EDITOR=/usr/bin/vi
export EDITOR
byebug ...
```

or in the `csh` shell,
```bash
setenv EDITOR /usr/bin/vi
byebug ...
```
