#!/usr/bin/env bash
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] START args: $@"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] BO_LOADED: $BO_LOADED"
. bash.origin BOE
cmd="$1"
shift
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] BO_LOADED: $BO_LOADED"

# TODO: Remove once 'bash.origin' is on bin path automatically
BO_ensure_nvm

if [[ "$(head -1 "$cmd")" == "#!/usr/bin/env bash.origin.script"* ]] ; then
    binName="$(which bash.origin.script)"
else
    binName="$(which bash.origin)"
fi

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] Calling: $binName $cmd $@"
BO_format "${BO_VERBOSE}" "HEADER" "Running: $binName $cmd"
set +e
BO_IS_TEST_RUN=1 BO_LOADED= BO_IS_SOURCING= BO_sourceProfile__sourced= "$binName" "$cmd" "$@"
rc=$?
set -e
BO_format "${BO_VERBOSE}" "FOOTER"
if [[ $rc != 0 ]]; then
    echo "[exit code: $rc]"
    exit 1
fi
exit 0
