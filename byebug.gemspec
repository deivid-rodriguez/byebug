# frozen_string_literal: true

require_relative "lib/byebug/version"

Gem::Specification.new do |s|
  s.name = "byebug"
  s.version = Byebug::VERSION
  s.authors = ["David Rodriguez", "Kent Sibilev", "Mark Moseley"]
  s.email = "deivid.rodriguez@riseup.net"
  s.license = "BSD-2-Clause"
  s.homepage = "https://github.com/deivid-rodriguez/byebug"
  s.summary = "Ruby fast debugger - base + CLI"
  s.description = "Byebug is a Ruby debugger. It's implemented using the
    TracePoint C API for execution control and the Debug Inspector C API for
    call stack navigation.  The core component provides support that front-ends
    can build on. It provides breakpoint handling and bindings for stack frames
    among other things and it comes with an easy to use command line interface."

  s.required_ruby_version = ">= 2.4.0"

  s.files = Dir["lib/**/*.rb", "lib/**/*.yml", "ext/**/*.[ch]", "LICENSE"]
  s.bindir = "exe"
  s.executables = ["byebug"]
  s.extra_rdoc_files = %w[CHANGELOG.md CONTRIBUTING.md README.md GUIDE.md]
  s.extensions = ["ext/byebug/extconf.rb"]
  s.require_path = "lib"

  s.add_development_dependency "bundler", "~> 2.0"
end
