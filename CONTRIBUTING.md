## Byebug as a C-extension

Byebug is a gem developed as a C-extension. The debugger internal's
functionality is implemented in C (the interaction with the TracePoint API).
The rest of the gem is implemented in Ruby. Normally you won't need to touch
the C-extension, but it will obviously depended on the bug you're trying to fix
or the feature you are willing to add. You can learn more about C-extensions
[here](http://tenderlovemaking.com/2009/12/18/writing-ruby-c-extensions-part-1.html)
or
[here](http://tenderlovemaking.com/2010/12/11/writing-ruby-c-extensions-part-2.html).


## Prerequisites

`Byebug` depends on the TracePoint API provided by `ruby-core`. This is a young
API and a lot of bugs have been recently corrected. Without this fixes,
`byebug` will fail to work properly, so make sure you have always the last
patch level releases of Ruby installed.


## Getting started

Once you have a local clone of `byebug`, you can start digging in the source
code. First run `bundle install` to get development & test dependencies
installed. Also make sure you compile the C-extension using `bundle exec rake
compile`, otherwise you won't be able to use your local clone. You can also run
the test suite as the default rake task (`bundle exec rake`). This task is
composed of 4 subtasks:

    bundle exec rake compile # compiles the C-extension
    bundle exec rake test # Run the test suite
    bundle exec rake rubocop # Run RuboCop's checks on the Ruby files
    bundle exec rake ccop # Run `indent`'s checks on the C files

After having done this, just read the code and improve it! Your contribution is
appreciated a lot!
