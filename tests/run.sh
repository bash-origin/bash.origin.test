#!/usr/bin/env bash

BO_READ_SELF_BASH_SOURCE="$""{BASH_SOURCE[0]:-$""0}"
eval BO_SELF_BASH_SOURCE="$BO_READ_SELF_BASH_SOURCE"
function BO_setResult {
		local  __resultvar=$1
    eval $__resultvar="'$2'"
		return 0
}
function BO_deriveSelfDir {
		# @source http://stackoverflow.com/a/246128/330439
		local SOURCE="$2"
		local DIR=""
		while [ -h "$SOURCE" ]; do
			  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
			  SOURCE="$(readlink "$SOURCE")"
			  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
		done
		BO_setResult $1 "$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		return 0
}
BO_deriveSelfDir __BO_DIR__ "$BO_SELF_BASH_SOURCE"

export BO_BASH=$(which bash)

if [[ "$SHELL" != *"/bash" ]]; then
    if [ "$_BO_TEST_LAUNCHED_BASH_4" == "1" ]; then
				echo >&2 "ERROR: bash version 4 required! (BO_BASH: $BO_BASH)"
				exit 1
		fi
		export _BO_TEST_LAUNCHED_BASH_4="1"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Launching '$__BO_DIR__/run.sh' using '$BO_BASH'"
		SHELL="$BO_BASH" "$BO_BASH" "$__BO_DIR__/run.sh" "$@"
		exit 0
fi
if [[ "$($SHELL --version)" != "GNU bash, version 4."* ]]; then
    if [ "$_BO_TEST_LAUNCHED_BASH_4" == "1" ]; then
				echo >&2 "ERROR: bash version 4 required! (BO_BASH: $BO_BASH)"
				exit 1
		fi
		export _BO_TEST_LAUNCHED_BASH_4="1"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Launching '$__BO_DIR__/run.sh' using '$BO_BASH'"
		SHELL="$BO_BASH" "$BO_BASH" "$__BO_DIR__/run.sh" "$@"
		exit 0
fi


# Source https://github.com/cadorn/bash.origin
if [ -z "${BO_LOADED}" ]; then
		. bash.origin BOE
fi
function init {
		eval BO_SELF_BASH_SOURCE="$BO_READ_SELF_BASH_SOURCE"
		BO_deriveSelfDir ___TMP___ "$BO_SELF_BASH_SOURCE"
		local __BO_DIR__="$___TMP___"


		# Ensure 'bash.origin' is on path (will be place in NVM bin dir`)
		# TODO: Ensure 'bash.origin' bin using own helper.
		BO_ensure_nvm



		# @source http://stackoverflow.com/a/3879077/330439
		function is_pwd_working_tree_clean {
				if echo "$@" | grep -q -Ee '(\$|\s*)--ignore-dirt(\s*|\$)'; then
						return 0
				elif echo "$npm_config_argv" | grep -q -Ee '"--ignore-dirt"'; then
						return 0
				fi
				# TODO: Only stop if sub-path is dirty (use bash.origin.git to get git root and use helper)
		    # Update the index
		    git update-index -q --ignore-submodules --refresh
		    # Disallow unstaged changes in the working tree
		    if ! git diff-files --quiet --ignore-submodules --; then
						return 1
		    fi
		    # Disallow uncommitted changes in the index
		    if ! git diff-index --cached --quiet HEAD --ignore-submodules --; then
						return 1
		    fi
				return 0
		}


    function runTest {
        local testName="$1"

        BO_format "${VERBOSE}" "HEADER" "Run test: $testName"

	      echo "$(BO_cecho "Test: $testName" WHITE BOLD)"

				pushd "$testName" > /dev/null

		        local rawResultPath=".actual.raw.log"
		        local actualResultPath=".actual.log"
		        local expectedResultPath=".expected.log"


						# TODO: Add actual files to ignore rules at git root using bash.origin.git (only if --record)


		        BO_resetLoaded
		        # Run test and record actual result
						testRootFile="$(pwd)/main.sh"
						if [ ! -e "$testRootFile" ]; then
								testRootFile="$(pwd)/main"
						fi
						if [ ! -e "$testRootFile" ]; then
									echo >&2 "$(BO_cecho "ERROR: Test entry point 'main[.sh]' not found! (pwd: $(pwd))" RED BOLD)"
									exit 1
						fi

						if [[ ! -x "$testRootFile" ]]; then
		        		if [ $RECORD == 0 ]; then
										echo >&2 "$(BO_cecho "ERROR: Test entry point '$testRootFile' not executable! Run with '--record' to fix. (pwd: $(pwd))" RED BOLD)"
										exit 1
								else
										echo "Making test entry point '$testRootFile' executable. (pwd: $(pwd))"
										chmod u+x "$testRootFile"
							  fi
						fi

						function invokeTest {

								# TODO: Write wrapper for 'testRootFile' that will log error message
								#       if exit code not 0 so that test will fail. Currently exit codes are ignored.
				        "$BO_BASH" "$__BO_DIR__/runner.sh" "$testRootFile" | tee "$rawResultPath"

								cp -f "$rawResultPath" "$actualResultPath"

								# Remove sections to be ignored
								sed -i -e '/TEST_MATCH_IGNORE>>>/,/<<<TEST_MATCH_IGNORE/d' "$actualResultPath"
								# Make paths in result relative
								ownPath=`echo "$(pwd)" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $ownPath"
								sed -i -e "s/$ownPath//g" "$actualResultPath"
								basePath=`echo "$testBaseDir" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $basePath"
								sed -i -e "s/$basePath//g" "$actualResultPath"
								homePath=`echo "$HOME" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $homePath"
								sed -i -e "s/$homePath//g" "$actualResultPath"

								if [ -e "$actualResultPath-e" ]; then
										rm "$actualResultPath-e"
								fi
						}

						invokeTest

						if [ ! -s "$actualResultPath" ]; then
								echo >&2 "$(BO_cecho "ERROR: Test result was empty! Re-running in verbose mode." RED BOLD)"

								echo "'which env': $(which env)"
								echo "'which bash.origin': $(which bash.origin)"
								echo "'which bash': $(which bash)"
								echo "'bash --version': $(bash --version)"
								echo "'ls -al (which bash.origin)': $(ls -al $(which bash.origin))"
								echo "PWD: $(pwd)"
								ls -al
                echo "########## Test File : $testRootFile >>>"
								cat "$testRootFile"
                echo "##########"

                echo "| ########## EXECUTING >>>"
						    set -x
								BO_VERBOSE=1 VERBOSE=1 "$BO_BASH" "$__BO_DIR__/runner.sh" "$testRootFile"
						    set +x
                echo "<<< EXECUTING ########## |"

                echo "[bash.origin.test] Not running more tests so you can fix issue above!"
								exit 1
						fi


		        if [ $RECORD == 0 ]; then

		            # Compare actual result with expected result
		            if [ ! -e "$expectedResultPath" ]; then
		                echo >&2 "$(BO_cecho "ERROR: Expected result not found at '$expectedResultPath'! Run tests with '--record' once to generate expected result." RED BOLD)"
		                exit 1
		            fi
								if ! diff -q "$expectedResultPath" "$actualResultPath" > /dev/null 2>&1; then
		                echo "$(BO_cecho "| ##################################################" RED BOLD)"
		                echo "$(BO_cecho "| # ERROR: Actual result does not match expected result for test '$testName'!" RED BOLD)"
		                echo "$(BO_cecho "| ##################################################" RED BOLD)"
		                echo "$(BO_cecho "| # $(ls -al "$expectedResultPath")" RED BOLD)"
		                echo "$(BO_cecho "| # $(ls -al "$actualResultPath")" RED BOLD)"
		                echo "$(BO_cecho "| # $(ls -al "$rawResultPath")" RED BOLD)"
		                echo "$(BO_cecho "| ########## ACTUAL : $rawResultPath >>>" RED BOLD)"
										cat "$rawResultPath"
		                echo "$(BO_cecho "| ########## ACTUAL : $actualResultPath >>>" RED BOLD)"
										cat "$actualResultPath"
		                echo "$(BO_cecho "| ########## EXPECTED : $expectedResultPath >>>" RED BOLD)"
										cat "$expectedResultPath"
		                echo "$(BO_cecho "| ########## DIFF >>>" RED BOLD)"
										set +e
										diff -u "$expectedResultPath" "$actualResultPath"
										set -e
		                echo "$(BO_cecho "| ##################################################" RED BOLD)"
										if ! is_pwd_working_tree_clean; then
		                		echo "$(BO_cecho "| # NOTE: Before you investigate this assertion error make sure you run the test with a clean git working directory!" RED BOLD)"
										fi
										# TODO: Optionally do not exit.
		                exit 1
		            fi
		  		      echo "$(BO_cecho "[bash.origin.test] Successful Test" GREEN BOLD)"
		        else

								echo "[bash.origin.test] Recording test session in '.expected.log' files."

		            # Keep actual result as expected result
		            cp -f "$actualResultPath" "$expectedResultPath"

		  		      echo "$(BO_cecho "[bash.origin.test] Test result recorded. Commit changes to git!" YELLOW BOLD)"
		        fi
				popd > /dev/null

        BO_format "${VERBOSE}" "FOOTER"
    }


		testBaseDir="$(pwd)/$1"
		testName="$2"

		if [ ! -d "$testBaseDir" ]; then
				echo >&2 "$(BO_cecho "ERROR: Directory '$testBaseDir' not found! (pwd: $(pwd))" RED BOLD)"
				exit 1
		fi

		pushd "$testBaseDir" > /dev/null


				export BO_PACKAGES_DIR="$(pwd)/.deps"
				export BO_SYSTEM_CACHE_DIR="$BO_PACKAGES_DIR"

		    local RECORD=0

				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_PACKAGES_DIR: $BO_PACKAGES_DIR"
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_SYSTEM_CACHE_DIR: $BO_SYSTEM_CACHE_DIR"
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"

				if echo "$@" | grep -q -Ee '(\$|\s*)--record(\s*|\$)'; then
		        RECORD=1
				elif echo "$npm_config_argv" | grep -q -Ee '"--record"'; then
				    RECORD=1
				fi


				if [ $RECORD == 1 ]; then
						if ! is_pwd_working_tree_clean; then
								echo >&2 "$(BO_cecho "ERROR: Cannot remove all temporary test assets before recording test run because git is not clean!" RED BOLD)"
								exit 1
						fi
		        git clean -d -x -f > /dev/null
				else
						if is_pwd_working_tree_clean; then
		        		git clean -d -x -f > /dev/null
						fi
				fi

				if [ -z "$testName" ]; then
						for mainpath in */main*; do
	            	runTest "$(dirname "$mainpath")"
						done
				else
						if [ ! -d "$testName-"* ]; then
								echo >&2 "$(BO_cecho "ERROR: Cannot find test with prefix '$testName-'" RED BOLD)"
								exit 1
						fi
						pushd "$testName-"* > /dev/null

		            runTest "$(echo "$mainpath" | sed 's/\/main$//')"

						popd > /dev/null
				fi
		popd > /dev/null
}
init "$@"
