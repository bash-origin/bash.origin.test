#!/usr/bin/env bash
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] START args: $@"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] BO_LOADED: $BO_LOADED"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] Souring 'bash.origin BOE'"
. bash.origin BOE
cmd="$1"
shift
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] BO_LOADED: $BO_LOADED"

if ! BO_has "node"; then
    BO_ensure_nvm
fi

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] Header for file $cmd: $(head -1 "$cmd")"

binName=""
if [[ "$(head -1 "$cmd")" == "#!/usr/bin/env bash.origin.script"* ]] ; then
    binName="$(which bash.origin.script)"
    binName=""
else
    if [[ "$(head -1 "$cmd")" == "#!/usr/bin/env bash.origin.test"* ]] ; then
        binName="$BO_TEST_PACKAGE_PATH/tests/run.sh"
    else
        if [[ "$(head -1 "$cmd")" == "#!/usr/bin/env bash.origin"* ]] ; then
            binName="$(which bash.origin)"
            binName=""
        else
            binName=""
        fi
    fi
fi

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runner.sh] Calling: $binName $cmd $@"

BO_format "${BO_VERBOSE}" "HEADER" "Running: $binName $cmd"
if [[ $BO_TEST_FLAG_PROFILE == 1 ]]; then
    BO_run_recent_node "$BO_TEST_PACKAGE_PATH/lib/profile.js" --log "$BO_TEST_RAW_RESULT_PATH" profile &
    sleep 1
fi

# If the workspace root is not set we default to our test directory to ensure we get
# stable implementation IDs based on the source file path (which is normalized relative to the workspace root).
if [ -z "$BO_WORKSPACE_ROOT" ]; then
    export BO_WORKSPACE_ROOT="$(pwd)"
fi

set +e
if [[ $BO_TEST_FLAG_PROFILE == 1 ]]; then
    time {
        set -x
        if [ "$binName" == "" ]; then
            BO_IS_TEST_RUN=1 \
                BO_LOADED= \
                BO_IS_SOURCING= \
                BO_sourceProfile__sourced= \
                __ON_INIT__BO_IS_SOURCING= \
                "$cmd" "$@"
        else
            BO_IS_TEST_RUN=1 \
                BO_LOADED= \
                BO_IS_SOURCING= \
                BO_sourceProfile__sourced= \
                __ON_INIT__BO_IS_SOURCING= \
                "$binName" "$cmd" "$@"
        fi
        set +x
        rc=$?
        echo "##### END_TEST_RESULT #####"
    }
    BO_run_recent_node "$BO_TEST_PACKAGE_PATH/lib/profile.js" --log "$BO_TEST_RAW_RESULT_PATH" summary
else
    if [ "$binName" == "" ]; then
        BO_IS_TEST_RUN=1 \
            BO_LOADED= \
            BO_IS_SOURCING= \
            BO_sourceProfile__sourced= \
            __ON_INIT__BO_IS_SOURCING= \
            "$cmd" "$@"
    else
        BO_IS_TEST_RUN=1 \
            BO_LOADED= \
            BO_IS_SOURCING= \
            BO_sourceProfile__sourced= \
            __ON_INIT__BO_IS_SOURCING= \
            "$binName" "$cmd" "$@"
    fi
    rc=$?
fi
set -e
BO_format "${BO_VERBOSE}" "FOOTER"
if [[ $rc != 0 ]]; then
    echo "[exit code: $rc]"
    exit 1
fi
exit 0
