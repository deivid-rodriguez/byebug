#!/usr/bin/env bash

gem update --system --no-document
gem install bundler --no-document
bundle install --jobs 3 --retry 3
bundle exec rake clobber compile test sign_hooks overcommit
