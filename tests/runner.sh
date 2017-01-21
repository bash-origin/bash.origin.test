#!/usr/bin/env bash
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] START args: $@"
. bash.origin BOE
cmd="$1"
shift

# TODO: Remove once 'bash.origin' is on bin path automatically
BO_ensure_nvm

binName="$(which bash.origin)"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] Calling: $binName $cmd $@"
set +e
BO_LOADED= BO_IS_SOURCING= BO_sourceProfile__sourced= "$binName" "$cmd" "$@"
rc=$?
if [[ $rc != 0 ]]; then
    echo "[exit code: $rc]"
    exit 1
fi
exit 0
