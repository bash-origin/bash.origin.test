#!/usr/bin/env bash
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

		export BO_PACKAGES_DIR="$__BO_DIR__/.deps"
		export BO_SYSTEM_CACHE_DIR="$BO_PACKAGES_DIR"

    local RECORD=0


		if echo "$@" | grep -q -Ee '(\$|\s*)--record(\s*|\$)'; then
        RECORD=1
		elif echo "$npm_config_argv" | grep -q -Ee '"--record"'; then
		    RECORD=1
		fi


		# @source http://stackoverflow.com/a/3879077/330439
		function is_pwd_working_tree_clean {
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
						binName="./main.sh"
						if [ ! -e "$binName" ]; then
								binName="./main"
						fi
						if [ ! -e "$binName" ]; then
									echo >&2 "$(BO_cecho "ERROR: Test entry point 'main[.sh]' not found! (pwd: $(pwd))" RED BOLD)"
									exit 1
						fi

						if [[ ! -x "$binName" ]]; then
		        		if [ $RECORD == 0 ]; then
										echo >&2 "$(BO_cecho "ERROR: Test entry point '$binName' not executable! (pwd: $(pwd))" RED BOLD)"
										exit 1
								else
										echo "Making test entry point '$binName' executable. (pwd: $(pwd))"
										chmod u+x "$binName"
							  fi
						fi
		        "$binName" | tee "$rawResultPath"

						if [ -s "$rawResultPath" ]; then
								echo >&2 "$(BO_cecho "ERROR: Test result was empty! Re-running in verbose mode." RED BOLD)"
								VERBOSE=1
								BO_VERBOSE=1
		        		"$binName" | tee "$rawResultPath"
						fi

						cp -f "$rawResultPath" "$actualResultPath"

						# Remove sections to be ignored
						sed -i -e '/TEST_MATCH_IGNORE>>>/,/<<<TEST_MATCH_IGNORE/d' "$actualResultPath"

						# Make paths in result relative
						basePath=`echo "$(dirname $__BO_DIR__)" | sed 's/\\//\\\\\\//g'`
						sed -i -e "s/$basePath//g" "$actualResultPath"
						homePath=`echo "$HOME" | sed 's/\\//\\\\\\//g'`
						sed -i -e "s/$homePath//g" "$actualResultPath"

						if [ -e "$actualResultPath-e" ]; then
								rm "$actualResultPath-e"
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
		                echo "$(BO_cecho "| ########## ACTUAL : $actualResultPath >>>" RED BOLD)"
										cat "$actualResultPath"
		                echo "$(BO_cecho "| ########## EXPECTED : $expectedResultPath >>>" RED BOLD)"
										cat "$expectedResultPath"
		                echo "$(BO_cecho "| ########## DIFF >>>" RED BOLD)"
										set +e
										diff -c "$expectedResultPath" "$actualResultPath"
										set -e
		                echo "$(BO_cecho "| ##################################################" RED BOLD)"
										if ! is_working_tree_clean; then
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


		baseDir="$1"
		testName="$2"

		if [ ! -d "$baseDir" ]; then
				echo >&2 "$(BO_cecho "ERROR: Directory '$baseDir' not found! (pwd: $(pwd))" RED BOLD)"
				exit 1
		fi

		pushd "$baseDir" > /dev/null

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
