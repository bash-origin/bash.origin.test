#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@com.github/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "jest": "^20.0.4"
            }
        }
    }
}

function EXPORTS_run {

    testRootFile="$1"

    workingDir="$(pwd)"
    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~facebook~jest] testRelpath: $testRelpath"

    echo ">>>TEST_IGNORE_LINE:^Time:\s+\d<<<"
    echo ">>>TEST_IGNORE_LINE:Test \([\d]+ms\)<<<"

    export NODE_PATH="$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules:$NODE_PATH"

    "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/.bin/jest" "$testRelpath" --config={
        "rootDir": "$workingDir",
        "testRegex": "(/__tests__/.*|(\\.|/)(test|spec))\\.jsx?|.+\\.js$"
    } --runInBand
}
