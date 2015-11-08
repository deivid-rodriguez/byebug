#!/bin/bash

# Construct names
ruby_version_name=ruby-$(git show -s --pretty=format:'%h')
ruby_install_dir=~/.rubies/$ruby_version_name

# Generate configure script if needed
if [[ ! -s configure || configure.in -nt configure ]]; then
  autoreconf || exit $?
fi

# Configure Ruby
./configure --disable-install-doc --prefix="$ruby_install_dir"

# Compile and install Ruby
make && make install

# Back to byebug dir (inferred from script's name)
cd "$(dirname "$0")/.." || exit

# Test Byebug against new Ruby
chruby-exec "$ruby_version_name" -- gem install bundler --no-document
chruby-exec "$ruby_version_name" -- bundle install --force
chruby-exec "$ruby_version_name" -- bundle exec rake clobber compile

# Set environment var to signal bisection
export NOCOV=true

if [[ "$1" = '--fixer' ]]
then
  if ! chruby-exec "$ruby_version_name" -- script/minitest_runner.rb "$2"
  then
    exit 0
  else
    exit 1
  fi
else
  chruby-exec "$ruby_version_name" -- script/minitest_runner.rb "$2" || exit 1
fi
