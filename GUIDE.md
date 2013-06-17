### Second Sample Session: Delving Deeper

In this section we'll introduce breakpoints, the call stack and restarting.
Below we will debug a simple Ruby program to solve the classic Towers of Hanoi
puzzle. It is augmented by the bane of programming: some command-parameter
processing with error checking.

```
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

```
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

```
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

```
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

```
(byebug) ARGV
[]
```

Ooops. We forgot to specify any parameters to this program. Let's try again. We can
use the `restart` command here.

```
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
--> #0  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol)
      at .../byebug/old_doc/hanoi.rb:4
    #1  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol)
      at .../byebug/old_doc/hanoi.rb:8
    #2  <top (required)> at .../byebug/old_doc/hanoi.rb:34
(byebug)
```

In the above we added new commands: `break` (see [breakpoints]()), which
indicates to stop just before that line of code is run, and `continue`, which
resumes execution.  Notice the difference between `display a` and 
`display a.inspect`. An implied string conversion is performed on the expression
after it is evaluated. To remove a display expression `undisplay` is used. If we
give a display number, just that display expression is removed.

We also used a new command `where`(see [backtrace]()) to show the call stack. In
the above situation, starting from the bottom line we see we called the `hanoi`
method from line 34 of the file `hanoi.rb` and the `hanoi` method called itself
two more times at line 4.

In the call stack we show a _current frame_ mark, the frame number, the method
being called, the names of the parameters, the types those parameters
_currently_ have and the file-line position. Remember it's possible that when
the program was called the parameters had different types, since the types of
variables can change dynamically. You can alter the style of what to show in the
trace (see [callstyle]()).

Now let's move around the callstack.

```
(byebug) undisplay
Clear all expressions? (y/n) y
(byebug:1) i_args
NameError Exception: undefined local variable or method `i_args' for main:Object
(byebug:1) frame -1
#3 at hanoi.rb:34
(byebug:1) i_args
1
(byebug:1) p n
3
(byebug:1) down 2
#1 Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol) at hanoi.rb:4
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


### Unit Testing Session

In the previous sessions we've been calling byebug right at the outset, but this
is probably not the mode of operation you will use the most. There are a number
of situations where calling byebug at the outset is impractical for a couple of
reasons:

* Byebug just doesn't work when run at the outset. Any debugging changes the
behavior or the program in slight and subtle ways, and sometimes this can hinder
finding bugs.
* There's a lot of code that needs to be run before the part you want to
inspect.  Running this code takes time and you don't want the overhead of
byebug.

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

```
if __FILE__ == $0
  t = triangle(3)
  puts t
end
```

Okay, we're now ready to write our unit test. We'll use `test/unit` which comes
with the standard Ruby distribution.  Here's the test code; it should be in the
same directory as `triangle.rb`.

```ruby
require 'test/unit'
require_relative 'triangle.rb'

class TestTri < Test::Unit::TestCase
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
  require 'byebug'
  byebug
  solutions = []
...
```

Now we run the program..
```
$ ruby test-triangle.rb
Run options:

# Running tests:

[1/1] TestTri#test_basic[5, 14] in test-triangle.rb
    5: 
    6: class TestTri < Test::Unit::TestCase
    7:   def test_basic
    8:     require 'byebug'
    9:     byebug
=> 10:     solutions = []
   11:     0.upto(5) do |i|
   12:       solutions << triangle(i)
   13:     end
   14:     assert_equal([0, 1, 3, 6, 10, 15], solutions,
(byebug)
```

and we see that we are stopped at line 10 just before the initialization of the
list `solutions`.

Now let's see where we are...
```
(byebug) where
--> #0  TestTri.test_basic at test-tri2.rb:10
Warning: saved frames may be incomplete; compare with caller(0)
(byebug)
```

Something seems wrong here; `TestTri.test_basic` indicates that we are in class
`TestTri` in method `test_basic`. However we don't see the call to this like we
did in the last example when we used the `where` command. This is because byebug
really didn't spring into existence until after we already had entered that
method, and Ruby doesn't keep call stack information around in a way that would
give the information we show when running `where`.

If we want call stack information, we have to turn call-stack tracking on
_beforehand_. This is done by adding `Byebug.start`.

Here's what our test program looks like after we modify it to start tracking
calls from the outset

```ruby
require 'test/unit'
require_relative 'triangle.rb'
require 'byebug'
Byebug.start

class TestTri < Test::Unit::TestCase
  def test_basic
    byebug
    solutions = []
    0.upto(5) do |i|
      solutions << triangle(i)
    end
    assert_equal([0, 1, 3, 6, 10, 15], solutions,
                 "Testing the first 5 triangle numbers")
  end
end
```

Now when we run this:
```
$ ruby test-triangle.rb
Run options:

# Running tests:

[1/1] TestTri#test_basic[5, 14] in test-triangle.rb
    5: 
    6: class TestTri < Test::Unit::TestCase
    7:   def test_basic
    8:     require 'byebug'
    9:     byebug
=> 10:     solutions = []
   11:     0.upto(5) do |i|
   12:       solutions << triangle(i)
   13:     end
   14:     assert_equal([0, 1, 3, 6, 10, 15], solutions,
(byebug) where
--> #0  TestTri.test_basic at test-triangle.rb:10
    #1  MiniTest::Unit::TestCase.run_test(name#String)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:858
    #2  MiniTest::Unit::TestCase.run(runner#Test::Unit::Runner)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1301
    #3  Test::Unit::TestCase.run(runner#Test::Unit::Runner)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit/testcase.rb:17
    #4  MiniTest::Unit._run_suite(suite#Class, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:919
    #5  Array.map(suite#Class, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:912
    #6  MiniTest::Unit._run_suite(suite#Class, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:912
    #7  Test::Unit::Runner._run_suites(suites#Array, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:657
    #8  Array.each(suites#Array, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:655
    #9  Test::Unit::Runner._run_suites(suites#Array, type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:655
    #10 MiniTest::Unit._run_anything(type#Symbol)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:867
    #11 MiniTest::Unit.run_tests
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1060
    #12 MiniTest::Unit._run(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1047
    #13 Array.each(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1046
    #14 MiniTest::Unit._run(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1046
    #15 MiniTest::Unit._run(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1042
    #16 MiniTest::Unit.run(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/minitest/unit.rb:1035
    #17 Test::Unit::RunCount.run(args#NilClass)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:21
    #18 Test::Unit::Runner.run(args#Array)
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:774
    #19 #<Class:Test::Unit::Runner>.autorun
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:366
    #20 Test::Unit::RunCount.run_once
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:27
    #21 #<Class:Test::Unit::Runner>.autorun
      at /home/davidr/.rvm/rubies/ruby-2.0.0-p195/lib/ruby/2.0.0/test/unit.rb:367
    #22 <main> at test-triangle.rb:6
(byebug)
```

Much better. But again let me emphasize that the parameter types are those of
the corresponding variables that _currently_ exist, and this might have changed
since the time when the call was made.


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

```
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

We've already seen two examples of such differences. One difference is the fact
that we stop on method definitions or `def`'s and that is because these are in
fact executable statements. In other compiled languages this would not happen
because that's already been done when you compile the program (or in Perl when
it scans in the program). The other difference we saw was our inability to show
call stack parameter types without having made arrangements for byebug to track
this. In other languages call stack information is usually available without
asking assistance of the debugger (in C and C++, however, you generally have to
ask the compiler to add such information.).

In this section we'll consider some other things that might throw off new users
to Ruby who are familiar with other languages and debugging in them.

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

```
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
* references to videos

## Getting in & out

### Starting byebug

There is a wrapper script called `byebug` which basically `require`'s the gem
then loads `byebug` before its argument (the program to be debugged) is started.

```
byebug [byebug-options] [--] ruby-script ruby-script-arguments
```

If you don't need to pass dash options to your program, which might be confused
with byebug options, then you don't need to add the `--`. To get a brief list of
options and descriptions, use the `--help` option.

```
$ byebug --help
byebug 1.4.0
Usage: byebug [options] <script.rb> -- <script.rb parameters>

Options:
 -A, --annotate LEVEL      Set annotation level
 -d, --debug               Set $DEBUG=true
 -I, --include PATH        Add PATH (single or multiple:path:list) to $LOAD_PATH
     --no-quit             Do not quit when script finishes
     --no-stop             Do not stop when script is loaded
 -nx                       Don't run any byebug initialization files
 -r, --require SCRIPT      Require library before script
     --restart-script FILE Name of the script file to run. Erased after read
     --script FILE         Name of the script file to run
    -x, --trace            Turn on line tracing

Common options:
        --verbose          Turn on verbose mode
        --help             Show this message
        --version          Print program version
    -v                     Print version number, then turn on verbose mode
```

Many options appear as a long option name, such as `--help` and a short one
letter option name, such as `-h`. The list of options is detailed below:

* **-h | --help**. It causes `byebug` to print some basic help and exit
* **-v | --version**. It causes `byebug` to print its version number and
exit.
* **-A | --annotate <level>**. Set gdb-style annotation `level`, a number.
Additional information is output automatically when program state is changed.
This can be used by front-ends such as GNU Emacs to post this updated
information without having to poll for it.
* **-d | --debug**. Set `$DEBUG` to `true`. Compatible with Ruby's.
* **-I | --include <path>**. Add `path` to load path. `path` can be a single
path ar a colon separated path list.
* **-m | --post-mortem**. If your program raises an exception that isn't caught
you can enter byebug for inspection of what went wrong. You may also want to use
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

```
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

```ruby
#<OpenStruct annotate=nil, nx=false, quit=true, restart_script=nil, script=nil,
stop=true, tracing=false, verbose_long=false>
```
