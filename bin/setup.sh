#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.4.20
gem install bundler --version 2.3.26 --force

bundle install

set -x
