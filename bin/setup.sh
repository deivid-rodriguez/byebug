#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.1.2
gem install bundler --version 2.1.4 --force

bundle install --jobs 3 --retry 3

set -x
