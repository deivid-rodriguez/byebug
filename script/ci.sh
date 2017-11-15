#!/usr/bin/env bash

bundle install --jobs 3 --retry 3
bundle exec rake clobber compile test sign_hooks overcommit
