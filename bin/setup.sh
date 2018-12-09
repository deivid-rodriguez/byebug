#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 2.7.8
gem install bundler --version 1.17.1 --force

bin/bundle install --jobs 3 --retry 3

set -x
