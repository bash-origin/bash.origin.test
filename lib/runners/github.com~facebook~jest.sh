#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@com.github/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "jest": "^21.2.1"
            }
        }
    }
}

function EXPORTS_run {

    testRootFile="$1"

    workingDir="$(pwd)"
    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~facebook~jest] testRelpath: $testRelpath"

    #echo ">>>TEST_IGNORE_LINE:^Time:\s+\d<<<"
    #echo ">>>TEST_IGNORE_LINE:Test \([\d]+ms\)<<<"

    echo ">>>TEST_IGNORE_LINE:\"startTime\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"duration\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"start\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"end\": \d+<<<"

    export NODE_PATH="$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules:$NODE_PATH"

    if [[ $BO_TEST_FLAG_INSPECT == 1 ]]; then

        echo "Running NodeJS with '--inspect-brk' which launches an interactive debugger ..."

        config={
            "rootDir": "$workingDir",
            "testRegex": "(/__tests__/.*|(\\.|/)(test|spec))\\.jsx?|.+\\.js$"
        }

        # TODO: Inspect the process that actually runs the test!
        #BO_VERSION_NVM_NODE=7
        BO_run_node --eval '
            const SPAWN = require("child_process").spawn;
            const EXEC = require("child_process").exec;
            const config = process.argv[1];
            const proc = SPAWN("'$(which node)'", [
                "--inspect-brk",
                "'$__DIRNAME__'/.rt/it.pinf.org.npmjs/node_modules/.bin/jest",
                "'$testRelpath'",
                "--config", config,
                "--runInBand"
            ]);
            proc.stdout.on("data", process.stdout.write);
            function launch (url) {
                EXEC("\"'$__DIRNAME__'/../open-in-google-chrome.sh\" \"" + url + "\"", function () {});
            }
            proc.stderr.on("data", function (data) {
                data = data.toString();
                if (launch && /chrome-devtools:\/\/devtools\//.test(data)) {
                    launch(data.match(/(chrome-devtools:\/\/devtools\/.+$)/m)[1]);
                    launch = null;
                }
                process.stderr.write(data);
            });
        ' "$config"

    else
        "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/.bin/jest" "$testRelpath" --config={
            "rootDir": "$workingDir",
            "testRegex": "(/__tests__/.*|(\\.|/)(test|spec))\\.jsx?|.+\\.js$",
            "reporters": [
                "$__DIRNAME__/jest-reporter.js"
            ]
        } --runInBand
    fi
}
