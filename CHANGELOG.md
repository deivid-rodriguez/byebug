## 1.4.1

* Fixes crash when printing some filenames in backtraces


## 1.4.0

* Byebug now uses the Debug Inspector API: faster and nicer!
* Fixes bug that prevents some random crashes


## 1.3.1

* Byebug now works with Rails debugging flag
* Fix bug which would make byebug crash when trying to print lines of code
containing the character '%'
* Fix bug which prevented basename and linetrace options from working together


## 1.3.0

* Support colon-delimited include paths in command-line front-end (@ender672)


## 1.2.0

* Added 'pry' command.
* Ctrl+C during command line editing is handled and works like pry/irb


## 1.1.1

* Better help system
* Code cleanup
* First version compatible with pry-byebug


## 1.1.0

* Post mortem support


## 1.0.3

* "autoreload" is set by default now
* "list" command: no negative line numbers shown, and line range behaves as
expected at the begining/end of file
* In some weird cases, "backtrace" command segfaults when trying to show info on
some frame args. Don't know the reason yet, but the exception is handled now and
and the command doesn't segfault anymore.
* Try some thread support (not even close to usable)


## 1.0.2

* "autolist" and "autoeval" are default settings now
* Fixes bug which messed up the call-stack when manipulating backtrace
information and when nexting/stepping


## 1.0.1

* Corrected small bug preventing byebug from loading


## 1.0.0

* Green test suite


## 0.0.1

* Initial release
