# Byebug [![Build Status](https://secure.travis-ci.org/deivid-rodriguez/byebug.png)](http://travis-ci.org/deivid-rodriguez/byebug) [![Code Climate](https://codeclimate.com/github/deivid-rodriguez/byebug.png)](https://codeclimate.com/github/deivid-rodriguez/byebug)

A Ruby 2.0 debugger.


## Install

Just type

    $ gem install byebug

or if you use bundler, drop

    gem 'byebug'

in your Gemfile


## Usage

Wherever you want to start debugging, simply drop:

    byebug

and the execution will stop and allow you to start debugging.

## Credits

Everybody who has ever contributed to this forked and reforked piece of
software, specially:

* Kent Sibilev and Mark Moseley, original authors of
[ruby-debug](https://github.com/mark-moseley/ruby-debug).
* Gabriel Horner, [debugger](https://github.com/cldwalker/debugger)'s mantainer.
* Koichi Sasada, author of the new C debugging API for Ruby.
* Dennis Ushakov, author of [debase](https://github.com/denofevil/debase), the
starting point of this.
