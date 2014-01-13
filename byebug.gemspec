require File.dirname(__FILE__) + '/lib/byebug/version'

Gem::Specification.new do |s|
  s.name        = 'byebug'
  s.version     = Byebug::VERSION
  s.authors     = ['David Rodriguez', 'Kent Sibilev', 'Mark Moseley']
  s.email       = 'deivid.rodriguez@mail.com'
  s.license     = 'BSD'
  s.homepage    = 'http://github.com/deivid-rodriguez/byebug'
  s.summary     = %q{Ruby 2.0 fast debugger - base + cli}
  s.description = %q{Byebug is a Ruby 2 debugger. It's implemented using the
    Ruby 2 TracePoint C API for execution control and the Debug Inspector C API
    for call stack navigation.  The core component provides support that
    front-ends can build on. It provides breakpoint handling and bindings for
    stack frames among other things and it comes with an easy to use command
    line interface.}

  s.required_ruby_version     = '>= 2.0.0'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- test/*`.split("\n")
  s.executables      = ['byebug']
  s.extra_rdoc_files = ['README.md']
  s.extensions       = ['ext/byebug/extconf.rb']

  s.add_dependency 'columnize', '~> 0.3'
  s.add_dependency 'debugger-linecache', '~> 1.2'

  s.add_development_dependency 'rake', '~> 10.1'
  s.add_development_dependency 'rake-compiler', '~> 0.9'
  s.add_development_dependency 'mocha', '~> 1.0'
  s.add_development_dependency 'minitest', '~> 5.2'
  s.add_development_dependency 'coveralls', '~> 0.7'
end
