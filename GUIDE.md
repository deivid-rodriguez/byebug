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

We also used a new command `where`(see [Backtrace]()) to show the call stack. In
the above situation, starting from the bottom line we see we called the `hanoi`
method from line 34 of the file `hanoi.rb` and the `hanoi` method called itself
two more times at line 4.

In the call stack we show a _current frame_ mark, the frame number, the method
being called, the names of the parameters, the types those parameters
_currently_ have and the file-line position. Remember it's possible that when
the program was called the parameters had different types, since the types of
variables can change dynamically. You can alter the style of what to show in the
trace (see [Callstyle]()).

Now let's more around the callstack.

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
