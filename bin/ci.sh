#!/usr/bin/env bash

bundle install --jobs 3 --retry 3 --path .bundle/gems
bundle exec rake
