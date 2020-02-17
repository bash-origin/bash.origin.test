#!/usr/bin/env bash.origin.script

function EXPORTS_run {

    testRootFile="$1"

    workingDir="$(pwd)"
    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~facebook~jest] testRelpath: $testRelpath"

    echo "TEST_MATCH_IGNORE>>>"
    if ! which jest; then
        npm install jest@25.1.0
    fi
    echo "<<<TEST_MATCH_IGNORE"

    #echo ">>>TEST_IGNORE_LINE:^Time:\s+\d<<<"
    #echo ">>>TEST_IGNORE_LINE:Test \([\d]+ms\)<<<"

    echo ">>>TEST_IGNORE_LINE:\"startTime\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"duration\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"start\": \d+<<<"
    echo ">>>TEST_IGNORE_LINE:\"end\": \d+<<<"

    if [[ $BO_TEST_FLAG_INSPECT == 1 ]]; then

        echo "Running NodeJS with '--inspect-brk' which launches an interactive debugger ..."

        config={
            "rootDir": "$workingDir",
            "testRegex": "(/__tests__/.*|(\\.|/)(test|spec))\\.jsx?|.+\\.js$"
        }

        # TODO: Inspect the process that actually runs the test!
        #BO_VERSION_NVM_NODE=7
        BO_run_node --eval '
            const BO_LIB = require("bash.origin.lib").forPackage(__dirname);
            const SPAWN = require("child_process").spawn;
            const EXEC = require("child_process").exec;
            const URL = require("url");
            const config = process.argv[1];
            const proc = SPAWN("'$(which node)'", [
                "--inspect-brk",
                "jest",
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
                if (launch && /Debugger listening on ws:\/\//.test(data)) {

                    const wsUrl = data.match(/Debugger listening on (ws:\/\/.+)/m)[1]
                    const wsUrl_parsed = URL.parse(wsUrl);

                    BO_LIB.LIB.REQUEST("http://" + wsUrl_parsed.host + "/json/list", function (err, response, body) {
                        const meta = JSON.parse(body)[0];
                        launch(meta.devtoolsFrontendUrl);
                        launch = null;
                    });
                }
                process.stderr.write(data);
            });
        ' "$config"

    else

        "jest" "$testRelpath" --config={
            "rootDir": "$workingDir",
            "testRegex": "(/__tests__/.*|(\\.|/)(test|spec))\\.jsx?|.+\\.js$",
            "reporters": [
                "$__DIRNAME__/jest-reporter.js"
            ]
        } --runInBand
    fi
}
