#!/usr/bin/env bash

gem uninstall bundler --force --executables
gem update --system 2.7.3
bundle install --jobs 3 --retry 3 --path .bundle/gems
bundle exec rake clobber compile test sign_hooks overcommit
