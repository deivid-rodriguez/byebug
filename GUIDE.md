## Second Sample Session: Delving Deeper

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
(byebug) where
--> #0  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol)
      at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:3
    #1  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol)
      at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:4
    #2  Object.hanoi(n#Fixnum, a#Symbol, b#Symbol, c#Symbol)
      at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:4
    #3  <main> at /home/davidr/Proyectos/byebug/old_doc/hanoi.rb:34
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


## Unit Testing Session

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


## Byebug.start with a block

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
