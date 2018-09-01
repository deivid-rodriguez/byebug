#!/usr/bin/env bash

set -eo pipefail

set +x

bin/bundle install --jobs 3 --retry 3
bin/rake

set -x
