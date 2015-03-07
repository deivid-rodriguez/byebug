#!/bin/bash
#
# Runs the tests a lot of times until one of them fails. This has helped me
# check for race conditions (that would manifest only sporadically) when
# implementing thread support.
#
# Usage Examples
#
# Run tests 8 times for each Ruby in 2.0, 2.1 and 2.2
#
#   $ ./loop_tests.sh
#
# Run tests 1 time for each Ruby in 2.0, 2.1 and 2.2
#
#   $ ./loop_tests.sh 1
#
# Run tests 3 times for each Ruby in 2.0 and 2.1
#
#   $ ./loop_tests.sh 3 2.0 2.1
#
compile="bundle exec rake compile"
run="bundle exec rake test"

if [ "$#" == "0" ]; then
  iterations=8
else
  iterations=$1
  shift
fi

if [ "$#" == "0" ]; then
  rubies=( 2.0 2.1 2.2 )
else
  rubies=( $@ )
fi

for version in "${rubies[@]}"; do
  rvm $version do $compile

  for i in `seq 1 $iterations`; do
    rvm $version do $run

    if [ "$?" != "0" ]; then
      exit
    fi
  done
done
