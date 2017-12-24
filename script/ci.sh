#!/usr/bin/env bash

gem install bundler -v 1.16.1 --no-document --conservative
bundle install --jobs 3 --retry 3 --path .bundle/gems
bundle exec rake clobber compile test sign_hooks overcommit
