#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.1.2
gem install bundler --version 2.2.0.rc.2 --force

bundle install

set -x
