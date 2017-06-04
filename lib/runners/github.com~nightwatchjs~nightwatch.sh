#!/usr/bin/env bash.origin.script

depend {
    "npm": {
        "@com.github/pinf-it/it.pinf.org.npmjs#s1": {
            "dependencies": {
                "nightwatch": "^0.9.15"
            }
        }
    }
}

# TODO: Relocate into plugin.
echo "TEST_MATCH_IGNORE>>>"
if ! BO_has geckodriver; then
    echo "Installing geckodriver ..."
    brew install geckodriver
fi
if ! BO_has chromedriver; then
    echo "Installing chromedriver ..."
    brew install chromedriver
fi
if ! BO_has selenium-server; then
    echo "Installing selenium-server-standalone ..."
    brew install selenium-server-standalone
fi
echo "<<<TEST_MATCH_IGNORE"



function PRIVATE_ensureSeleniumServerRunning {
    local status=$(curl --write-out %{http_code} --silent --output /dev/null "http://localhost:4444")
    if [ "$status" == "000" ]; then
        BO_log "$VERBOSE" "Starting selenium server ..."
        # TODO: Direct output to logfile
        selenium-server &
        sleep 2
    fi
}



function EXPORTS_run {

    testRootFile="$1"

    workingDir="$(pwd)"
    testRelpath="$(BO_relative "$workingDir" "$testRootFile")"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~nightwatchjs~nightwatch] testRelpath: $testRelpath"


    PRIVATE_ensureSeleniumServerRunning


    local rtBaseDir="$(pwd)/.rt/bash.origin.test"

    BO_ensure_dir "$rtBaseDir"

    local configPath="${rtBaseDir}/nightwatch.json"

    echo {
        "src_folders" : [],
        "output_folder" : "${rtBaseDir}/reports",
        "custom_commands_path" : "",
        "custom_assertions_path" : "",
        "page_objects_path" : "",
        "globals_path" : "",
        "selenium" : {
            "start_process" : false,
            "server_path" : "",
            "log_path" : "",
            "port" : 4444,
            "cli_args" : {
                "webdriver.chrome.driver" : "",
                "webdriver.gecko.driver" : ""
            }
        },
        "test_settings" : {
            "default" : {
                "launch_url" : "http://localhost",
                "selenium_port"  : 4444,
                "selenium_host"  : "localhost",
                "silent": true,
                "screenshots" : {
                    "enabled" : false,
                    "path" : ""
                },
                "desiredCapabilities": {
                    "browserName": "firefox",
                    "marionette": true
                }
            },
            "chrome" : {
                "desiredCapabilities": {
                    "browserName": "chrome"
                }
            }
        }
    } > "${configPath}"


    function testEnv {
        "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/.bin/nightwatch" \
            --config "${configPath}" \
            --test "$testRelpath" \
            --env "$1"
    }

    echo ">>>TEST_IGNORE_LINE:\d milliseconds.\$<<<"

    testEnv "default"
    testEnv "chrome"

}
