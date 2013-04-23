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
