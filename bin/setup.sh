#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.0.2
gem install bundler --version 2.0.1 --force

bundle install --jobs 3 --retry 3

set -x
