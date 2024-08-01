#!/usr/bin/env bash

set -eo pipefail

set +x

gem update --system 3.4.20

bundle install

set -x
