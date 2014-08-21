require File.dirname(__FILE__) + '/lib/byebug/version'

Gem::Specification.new do |s|
  s.name        = 'byebug'
  s.version     = Byebug::VERSION
  s.authors     = ['David Rodriguez', 'Kent Sibilev', 'Mark Moseley']
  s.email       = 'deivid.rodriguez@mail.com'
  s.license     = 'BSD'
  s.homepage    = 'http://github.com/deivid-rodriguez/byebug'
  s.summary     = 'Ruby 2.0 fast debugger - base + CLI'
  s.description = "Byebug is a Ruby 2 debugger. It's implemented using the
    Ruby 2 TracePoint C API for execution control and the Debug Inspector C API
    for call stack navigation.  The core component provides support that
    front-ends can build on. It provides breakpoint handling and bindings for
    stack frames among other things and it comes with an easy to use command
    line interface."

  s.required_ruby_version     = '>= 2.0.0'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- test/*`.split("\n")
  s.bindir           = 'bin'
  s.executables      = ['byebug']
  s.extra_rdoc_files = %w(README.md GUIDE.md)
  s.extensions       = ['ext/byebug/extconf.rb']
  s.require_path     = 'lib'

  s.add_dependency 'columnize', '~> 0.8'
  s.add_dependency 'slop', '~> 3.6'
  s.add_dependency 'debugger-linecache', '~> 1.2'
end
