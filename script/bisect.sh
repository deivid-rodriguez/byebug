#!/bin/bash

#
# Prints usage information
#
function help() {
  cat <<HELP

  script/bisect.sh <good_commit_sha1> <bad_commit_sha1> <test_name>

  @example

  script/bisect.sh 990a0bb 934546e test_finish_0_works_in_complicated_setups

  Given a known good revision and a known bad revision, finds the commit in
  ruby-core that broke or fixed a specific test in byebug. If the good commit is
  previous to the bad commit, it will find the commit which broke the test.
  Otherwise, it will find the commit which fixed it.

HELP
}

#
# Clones Ruby repo and switches to it
#
function clone_ruby() {
  local ruby_src_dir=~/src/ruby-head

  git clone git@github.com:ruby/ruby.git "$ruby_src_dir"

  cd "$ruby_src_dir" || exit
}

#
# Bisects the cloned ruby
#
function bisect_ruby() {
  git bisect start
  git bisect good "$1"
  git bisect bad "$2" 2>/dev/null

  if [[ "$?" = '0' ]]
  then
    git bisect run "$byebug_dir/script/check_revision.sh" "$3"
  else
    git bisect reset
    git bisect start
    git bisect good "$2"
    git bisect bad "$1"
    git bisect run "$byebug_dir/script/check_revision.sh" --fixer "$3"
  fi
}

#
# Main script
#

if [[ $# -ne 3 ]]; then
  help
  exit
fi

byebug_dir=$(cd "$(dirname "$0")/.." || exit && pwd)

clone_ruby

bisect_ruby "$1" "$2" "$3"
