#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.0.1
gem install bundler --version 1.17.3 --force

bin/bundle install --jobs 3 --retry 3

set -x
