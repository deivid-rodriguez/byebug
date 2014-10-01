if RUBY_VERSION < '2.0'
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

RbConfig::MAKEFILE_CONFIG['CFLAGS'] << ' -Wall -Werror -Wno-unused-parameter'
RbConfig::MAKEFILE_CONFIG['CFLAGS'] << ' -gdwarf-2 -g3 -O0' if ENV['debug']

dir_config('ruby')
create_makefile('byebug/byebug')
