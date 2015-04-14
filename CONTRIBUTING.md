## Getting started

The following steps should help you getting started:

* `Byebug` depends on the TracePoint API provided by `ruby-core`. This is a
young API and a lot of bugs have been recently corrected, so make sure you
always have the lastest patch level release installed.
* Get a local clone of `byebug`'s source code.
* Run `bundle install` to get development & test dependencies installed.
* Install the [overcommit][] hooks using `bundle exec overcommit --install`.
They will review your changes before they are committed, checking they are
consistent with the project's code style. If you're changing C files, make sure
you have the GNU indent utility installed in your system. `sudo apt-get install
indent` for linux or `brew install gnu-indent --with-default-names` should do
the job.
* Make sure you compile the C-extension using `bundle exec rake compile`.
Otherwise you won't be able to use `byebug`.
* Run the test suite using the default rake task (`bundle exec rake`). This
task is composed of 2 subtasks: `bundle exec rake compile` && `bundle exec rake
test`.

After having done this, just read the code and improve it! Your contribution is
appreciated a lot!

[overcommit]: https://github.com/brigade/overcommit/

## Byebug as a C-extension

Byebug is a gem developed as a C-extension. The debugger internal's
functionality is implemented in C (the interaction with the TracePoint API).
The rest of the gem is implemented in Ruby. Normally you won't need to touch
the C-extension, but it will obviously depended on the bug you're trying to fix
or the feature you are willing to add. You can learn more about C-extensions
[here](http://tenderlovemaking.com/2009/12/18/writing-ruby-c-extensions-part-1.html)
or
[here](http://tenderlovemaking.com/2010/12/11/writing-ruby-c-extensions-part-2.html).
