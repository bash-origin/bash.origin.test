#!/usr/bin/env bash
. bash.origin BOE
BO_resetLoaded
cmd="$1"
shift
[ -z "$BO_VERBOSE" ] || BO_log "$BO_VERBOSE" "[bash.origin.test][runner.sh] Calling: $cmd $@"
set +e
export SHELL_RESOLVED=$(which bash)
"$SHELL_RESOLVED" "$cmd" "$@"
rc=$?
if [[ $rc != 0 ]]; then
    echo "[exit code: $rc]"
    exit 1
fi
exit 0
