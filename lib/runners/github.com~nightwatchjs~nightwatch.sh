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
    local downloadsPath="${rtBaseDir}/downloads"

    if [ ! -e "${downloadsPath}" ]; then
        mkdir -p "${downloadsPath}"
    fi

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~nightwatchjs~nightwatch] declare config"
    
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
                    "browserName": "chrome",
                    "chromeOptions" : {
                        "prefs" : { 
                            "download": {
                                "default_directory": "${downloadsPath}",
                                "prompt_for_download": false
                            },
                            "profile": {
                                "default_content_setting_values" : {
                                    "automatic_downloads": 1
                                }
                            }
                        }
                    }
                }
            }
        }
    } > "${configPath}"

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~nightwatchjs~nightwatch] update config"

    local environments=$(BO_run_silent_node --eval '
        const PATH = require("path");
        const FS = require("fs");

        var runnerConfigPath = process.argv[1];
        var testPath = PATH.resolve(process.cwd(), process.argv[2]);

        var testCode = FS.readFileSync(testPath, "utf8").replace(/\n/g, "\\n");
        var testConfig = testCode.match(/\/\*\\nmodule\.config =(.+?)\\n\*\//);

        var runnerConfig = JSON.parse(FS.readFileSync(runnerConfigPath));

        if (testConfig) {
            testConfig = testConfig[1].replace(/\\n/g, "\n");
            try {
                testConfig = JSON.parse(testConfig);
            } catch (err) {
                console.error("Error parsing testConfig from file: " + testPath);
                throw err;
            }

            if (
                testConfig.browsers &&
                testConfig.browsers.length > 0
            ) {
                if (testConfig.browsers.indexOf("chrome") === -1) {
                    delete runnerConfig.test_settings.chrome;
                } else
                if (testConfig.browsers.indexOf("firefox") === -1) {
                    runnerConfig.test_settings.default.desiredCapabilities = runnerConfig.test_settings.chrome.desiredCapabilities;
                    delete runnerConfig.test_settings.chrome;
                }
            }

            if (testConfig.test_runner) {
                runnerConfig.test_runner = testConfig.test_runner;
            }

            FS.writeFileSync(runnerConfigPath, JSON.stringify(runnerConfig, null, 4), "utf8");
        }

        process.stdout.write(Object.keys(runnerConfig.test_settings).join(","));
    ' "${configPath}" "${testRelpath}")

    [ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][runners/github.com~nightwatchjs~nightwatch] run tests"

    function testEnv {

        # TODO: Get dynamic port.
        export PORT=8080

#        if [ -e "$__DIRNAME__/../../../github.com~bash-origin~bash.origin.express" ]; then
#            rm -Rf "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/bash.origin.express" || true
#            ln -s "../../../../../../github.com~bash-origin~bash.origin.express" "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/bash.origin.express"
#        fi

        echo ">>>TEST_IGNORE_LINE:Test (.+)<<<"

        export NODE_PATH="$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules:$NODE_PATH"

        "$__DIRNAME__/.rt/it.pinf.org.npmjs/node_modules/.bin/nightwatch" \
            --config "${configPath}" \
            --test "$testRelpath" \
            --env "$1"
    }

    echo ">>>TEST_IGNORE_LINE:\d milliseconds.\$<<<"

    echo "environments: ${environments}"

    for i in $(echo $environments | sed "s/,/ /g"); do
        testEnv "$i"
    done

}
