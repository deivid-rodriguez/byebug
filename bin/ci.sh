#!/usr/bin/env bash

bin/bundle install --jobs 3 --retry 3 --path .bundle/gems
bin/rake
