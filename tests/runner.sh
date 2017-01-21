#!/usr/bin/env bash
. bash.origin BOE
BO_resetLoaded
cmd="$1"
shift
"$cmd" "$@"
rc=$?
if [[ $rc != 0 ]]; then
    echo "exit code: $rc"
    exit 1
fi
exit 0
