#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@com.github/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "mocha": "^3.5.3"
            }
        }
    }
}

function EXPORTS_run {

    testRootFile="$1"

    workingDir="$(pwd)"
    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~mochajs~mocha] testRelpath: $testRelpath"

    export NODE_PATH="$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules:$NODE_PATH"

    echo ">>>TEST_IGNORE_LINE:\d+\spassing\s\([^\)]+\)<<<"

    if [[ $BO_TEST_FLAG_INSPECT == 1 ]]; then

        echo "Running NodeJS with '--inspect-brk' which launches an interactive debugger ..."

        BO_VERSION_NVM_NODE=7
        BO_run_node --eval '
            const SPAWN = require("child_process").spawn;
            const EXEC = require("child_process").exec;
            const config = process.argv[1];
            const proc = SPAWN("'$(which node)'", [
                "'$__DIRNAME__'/.rt/it.pinf.org.npmjs/node_modules/.bin/mocha",
                "--inspect-brk",
                "'$testRelpath'"
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
        '
    else
        "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/.bin/mocha" "$testRelpath"
    fi
}
