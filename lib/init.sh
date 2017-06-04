#!/usr/bin/env bash.origin.script

depend {
    "git": "@com.github/bash-origin/bash.origin.gitscm#s1"
}


function EXPORTS_init {

    local testDir="$1"

    BO_log "$VERBOSE" "testDir: $testDir"

    if [ -e "$testDir" ]; then
        echo "ERROR: Cannot 'init' as directory exists at: $testDir"
        exit 1
    fi

    local gitRoot=$(CALL_git get_closest_parent_git_root)
    BO_log "$VERBOSE" "gitRoot: $gitRoot"
    local projectRoot="$(dirname "$gitRoot")"
    BO_log "$VERBOSE" "projectRoot: $projectRoot"
    local projectName="$(basename "$projectRoot")"
    BO_log "$VERBOSE" "projectName: $projectName"


    local testSubpath=$(BO_relative "${projectRoot}" "${testDir}")
    BO_log "$VERBOSE" "testSubpath: $testSubpath"

    mkdir -p $testSubpath

    local testGroupSubpath=$(dirname "$testSubpath")
    BO_log "$VERBOSE" "testGroupSubpath: $testGroupSubpath"


    pushd "$projectRoot" > /dev/null

        if [ ! -e "package.json" ]; then

            local fromPath="$__DIRNAME__/init.tpl/package.json"

            BO_log "$VERBOSE" "Copy project template from '$fromPath' to 'package.json'"
            cp -f "$fromPath" "package.json"

            sed -i -e "s/%%%NAME%%%/${projectName}/g" "package.json"
            sed -i -e "s/%%%TESTS_SEARCH_PATH%%%/${testGroupSubpath}/g" "package.json"

            function getLatestPackageVersion {
                echo $(BO_run_recent_node --eval '
                    const INFO = JSON.parse(process.argv[1]);
                    process.stdout.write(INFO.version);
                ' "$(npm info $1 --json)")
            }

            local bashOriginVerion="$(getLatestPackageVersion "bash.origin")"
            BO_log "$VERBOSE" "bashOriginVerion: ${bashOriginVerion}"

            local bashOriginTestVerion="$(getLatestPackageVersion "bash.origin.test")"
            BO_log "$VERBOSE" "bashOriginTestVerion: ${bashOriginTestVerion}"

            sed -i -e "s/%%%BASH_ORIGIN_VERSION%%%/${bashOriginVerion}/g" "package.json"
            sed -i -e "s/%%%BASH_ORIGIN_TEST_VERSION%%%/${bashOriginTestVerion}/g" "package.json"

            [[ -z $VERBOSE ]] || cat "package.json"
            rm "package.json-e" || true
        fi

        if [ ! -e ".gitignore" ]; then

            local fromPath="$__DIRNAME__/init.tpl/.gitignore"

            BO_log "$VERBOSE" "Copy project template from '$fromPath' to '.gitignore'"
            cp -f "$fromPath" ".gitignore"
        fi

    popd > /dev/null

    if BO_ensure_empty_path "${testSubpath}"; then
        # Path is empty
        rm -Rf "${testSubpath}"

        BO_log "$VERBOSE" "Copy template from $__DIRNAME__/init.tpl/test to ${testSubpath}"
        cp -Rf "$__DIRNAME__/init.tpl/test" "${testSubpath}"
    fi
}
