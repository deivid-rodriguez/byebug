#!/usr/bin/env bash

set -eo pipefail

set +x

bin/bundle install --jobs 3 --retry 3 --path .bundle
bin/rake

set -x
