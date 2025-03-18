#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.6.6

bundle install

set -x
