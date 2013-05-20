#!/bin/bash
# Script to grep the for the given string in the given path on the given hosts

#set -xv
EXPECTED_ARGS=3
numargs=$#

if [[ "$1" == -* ]]
then
  grep_args="$1"
  shift
  EXPECTED_ARGS=4
fi

if [ $numargs -lt $EXPECTED_ARGS ]; then
  echo "Usage: dgrep.sh [grep_args] term path hosts..."
  exit
fi

# Add -r if not already present
if [[ "$grep_args" != "-r" ]]
then
  grep_args="$grep_args -r"
fi

# Add -n if not already present
if [[ "$grep_args" != "-n" ]]
then
  grep_args="$grep_args -n"
fi

term="$1"
path="$2"

# Shift to remove the path and term, leaving the hosts
shift
shift

echo "Grepping for [$term] in [$path] on [$@]"

for host in "$@"
do
  echo "=== Results from $host ==="
  ssh $host grep $grep_args \"$term\" \"$path\"
  #echo ssh $host grep $grep_args \'\"$term\" \"$path\"\'
done
