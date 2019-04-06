#!/usr/bin/env bash.origin.script

function EXPORTS_run {

    testRootFile="$1"
    rawResultPath="$2"

    [ -z "$BO_VERBOSE" ] || echo "BO_BASH: $BO_BASH"

    "$BO_BASH" "$__BO_DIR__/runner.sh" "$testRootFile" 2>&1 | tee "$rawResultPath"
}
