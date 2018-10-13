#!/usr/bin/env bash.origin.script

function EXPORTS_run {

    testRootFile="$1"
    workingDir="$(pwd)"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~mochajs~mocha] testRootFile: $testRootFile"
    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~mochajs~mocha] workingDir: $workingDir"

    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~mochajs~mocha] testRelpath: $testRelpath"

    echo ">>>TEST_IGNORE_LINE:\d+\spassing\s\([^\)]+\)<<<"

    if [[ $BO_TEST_FLAG_INSPECT == 1 ]]; then

        echo "Running NodeJS with '--inspect-brk' which launches an interactive debugger ..."

        BO_VERSION_NVM_NODE=7
        BO_run_node --eval '
            const BO_LIB = require("bash.origin.lib").forPackage(__dirname);
            const SPAWN = require("child_process").spawn;
            const EXEC = require("child_process").exec;
            const URL = require("url");
            const config = process.argv[1];
            const proc = SPAWN("'$(which node)'", [
                BO_LIB.binPath + "/mocha",
                "--inspect-brk",
                "'$testRelpath'"
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
        '
    else
        "$(bash.origin.lib binPath)/mocha" "$testRelpath"
    fi
}
