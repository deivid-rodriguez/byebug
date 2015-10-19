#!/bin/bash

#
# Prints usage information
#
function help() {
  cat <<HELP

  script/bisect.sh <good_commit_sha1> <bad_commit_sha1>

  Given a known good revision and a known bad revision, finds the commit in
  ruby-core that broke byebug's build.

HELP
}

#
# Clones Ruby repo and switches to it
#
function clone_ruby() {
  local ruby_src_dir=$byebug_dir/tmp/ruby_src

  git clone git@github.com:ruby/ruby.git "$ruby_src_dir"

  cd "$ruby_src_dir" || exit
}

#
# Bisects the cloned ruby
#
function bisect_ruby() {
  git bisect start
  git bisect good "$1"
  git bisect bad "$2"
  git bisect run "$byebug_dir/script/check_revision.sh"
}

#
# Main script
#

if [[ $# -ne 2 ]]; then
  help
  exit
fi

byebug_dir=$(cd "$(dirname "$0")/.." || exit && pwd)

clone_ruby

bisect_ruby "$1" "$2"
