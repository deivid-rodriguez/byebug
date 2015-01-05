if RUBY_VERSION < '2.0'
  STDERR.print("Ruby version is too old\n")
  exit(1)
end

require 'mkmf'

makefile_config = RbConfig::MAKEFILE_CONFIG

makefile_config['CC'] = ENV['CC'] if ENV['CC']

makefile_config['CFLAGS'] << ' -Wall -Werror -Wno-unknown-warning-option'
makefile_config['CFLAGS'] << ' -gdwarf-2 -g3 -O0' if ENV['debug']

dir_config('ruby')
with_cflags(makefile_config['CFLAGS']) { create_makefile('byebug/byebug') }
