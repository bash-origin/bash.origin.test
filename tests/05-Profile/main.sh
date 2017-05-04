#!/usr/bin/env bash.origin


export _BO_OPTIMIZED=1


echo "START: Script"
echo "TEST_MATCH_IGNORE>>>"
export BO_LOADED=0
export BO_VERBOSE=1
export VERBOSE=1
./script.bo.sh
echo "<<<TEST_MATCH_IGNORE"
echo "END: Script"


echo "START: Source"
echo "TEST_MATCH_IGNORE>>>"
export BO_LOADED=
export BO_VERBOSE=1
export VERBOSE=1
. "$BO_ROOT_SCRIPT_PATH"
echo "<<<TEST_MATCH_IGNORE"
echo "END: Source"


echo "OK"
