#!/usr/bin/env bash

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_VERBOSE: $BO_VERBOSE"
[ -z "$BO_TRACE" ] || echo "[bash.origin.test][run.sh] BO_TRACE: $BO_TRACE"

[ -z "$BO_TRACE" ] || echo -e "[bash.origin.test][run.sh] printenv:\n$(printenv)"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] pwd: $(pwd)"


function ensureBash4 {
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

		function installBashOrExit  {
			INSTALL_BASH=0
			if echo "$@" | grep -q -Ee '(\$|\s*)--install-bash(\s*|\$)'; then
				INSTALL_BASH=1
			elif echo "$npm_config_argv" | grep -q -Ee '"--install-bash"'; then
				INSTALL_BASH=1
			fi
			if [ $INSTALL_BASH == 1 ]; then
				if [[ $OSTYPE == *"darwin"* ]]; then
					# OSX
					echo "Installing 'bash' using 'brew' ..."
					# @see https://johndjameson.com/blog/updating-your-shell-with-homebrew/
					brew install bash
					export SHELL="/usr/local/bin/bash"
				else
					echo >&2 "[bash.origin.test][run.sh] ERROR: Cannot determine how to install bash version 4 for your OS '$OSTYPE'!"
					exit 1
				fi
			else
				echo >&2 "[bash.origin.test][run.sh] ERROR: bash version 4 required! (BO_BASH: $BO_BASH)"
				exit 1
			fi
		}

		if [[ "$SHELL" != *"/bash" ]]; then
		    if [ "$_BO_TEST_LAUNCHED_BASH_4" == "1" ]; then
				installBashOrExit "$@"
			fi
			export _BO_TEST_LAUNCHED_BASH_4="1"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Launching '$__BO_DIR__/run.sh' using '$BO_BASH'"
			SHELL="$BO_BASH" "$BO_BASH" "$__BO_DIR__/run.sh" "$@"
			exit 0
		fi
		if [[ "$($SHELL --version)" != "GNU bash, version 4."* ]]; then
		    if [ "$_BO_TEST_LAUNCHED_BASH_4" == "1" ]; then
				installBashOrExit "$@"
			fi
			export _BO_TEST_LAUNCHED_BASH_4="1"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Launching '$__BO_DIR__/run.sh' using '$BO_BASH'"
			SHELL="$BO_BASH" "$BO_BASH" "$__BO_DIR__/run.sh" "$@"
			exit 0
		fi
}
ensureBash4 "$@"

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"
[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH --version: $($BO_BASH --version)"

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Original BO_ROOT_SCRIPT_PATH: $BO_ROOT_SCRIPT_PATH"
if [ -z "$BO_ROOT_SCRIPT_PATH" ]; then
		if [ -e "$__BO_DIR__/../node_modules/bash.origin/bash.origin" ]; then
				BO_ROOT_SCRIPT_PATH="$__BO_DIR__/../node_modules/bash.origin/bash.origin"
		fi
fi
if [ ! -e "$BO_ROOT_SCRIPT_PATH" ] && [ "$BO_ROOT_SCRIPT_PATH" == "$(pwd)/node_modules/bash.origin/bash.origin" ]; then
		if [ -e "$(pwd)/bash.origin" ]; then
				# We are testing bash.origin package which should use itself
				BO_ROOT_SCRIPT_PATH="$(pwd)/bash.origin"
		elif [ -e "$(pwd)/.bash.origin" ]; then
				# The package is including it's own custom bash.origin source
				BO_ROOT_SCRIPT_PATH="$(pwd)/.bash.origin"
		fi
fi

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Using BO_ROOT_SCRIPT_PATH: $BO_ROOT_SCRIPT_PATH"

if [ ! -e "$HOME/.bash.origin" ]; then
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Installing '$BO_ROOT_SCRIPT_PATH' to '$HOME/.bash.origin'!"
		"$BO_BASH" "$BO_ROOT_SCRIPT_PATH" BO install
fi

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_LOADED: ${BO_LOADED}"

# Source https://github.com/cadorn/bash.origin
if [ -z "${BO_LOADED}" ]; then
		if type bash.origin > /dev/null 2>&1; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Running: . bash.origin BOE (which bash.origin: $(which bash.origin))"
				. bash.origin BOE
		elif [ -e "$HOME/.bash.origin" ]; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Running: . $HOME/.bash.origin"
				. "$HOME/.bash.origin"
		elif [ -e "$__BO_DIR__/../node_modules/bash.origin/bash.origin" ]; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Running: . $__BO_DIR__/../node_modules/bash.origin/bash.origin"
				. "$__BO_DIR__/../node_modules/bash.origin/bash.origin"
		else
				echo >&2 "[bash.origin.test][run.sh] ERROR: 'bash.origin' could not be found!"
				exit 1
		fi
fi
function init {
		eval BO_SELF_BASH_SOURCE="$BO_READ_SELF_BASH_SOURCE"
		BO_deriveSelfDir ___TMP___ "$BO_SELF_BASH_SOURCE"
		local __BO_DIR__="$___TMP___"


		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] init()"


		# TODO: Optionally source profile in runner? Move this to runner.
		# Source profile to get access to path variables
		# TODO: Save all ENV variables except for PATH?
		#BO_ENABLE_SOURCE_PROFILE=1
		#BO_sourceProfile


		# Ensure 'bash.origin' is on path (will be place in NVM bin dir`)
		# TODO: Ensure 'bash.origin' bin using own helper.
		BO_ensure_nvm


		# @source http://stackoverflow.com/a/3879077/330439
		function is_pwd_working_tree_clean {
			if echo "$@" | grep -q -Ee '(\$|\s*)--ignore-dirty?(\s*|\$)'; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'true' due to --ignore-dirty"
				return 0
			elif echo "$npm_config_argv" | grep -q -Ee '"--ignore-dirty?"'; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'true' due to --ignore-dirty"
				return 0
			fi
			# TODO: Only stop if sub-path is dirty (use bash.origin.git to get git root and use helper)
		    # Update the index
		    git update-index -q --ignore-submodules --refresh
		    # Disallow unstaged changes in the working tree
		    if ! git diff-files --quiet --ignore-submodules --; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'false' due to unstaged changes"
				return 1
		    fi
		    # Disallow uncommitted changes in the index
		    if ! git diff-index --cached --quiet HEAD --ignore-submodules --; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'false' due to uncommitted changes"
				return 1
		    fi
			if [[ ! -z $(git status -s) ]]; then
				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'false' due to 'git status -s'"
				return 1
			fi
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] is_pwd_working_tree_clean() 'true'"
			return 0
		}


    function runTest {
        local testName="$1"

        BO_format "${VERBOSE}" "HEADER" "Run test: $testName"

	      echo "$(BO_cecho "[bash.origin.test] Test: $testName" WHITE BOLD)"

				pushd "$testName" > /dev/null

					local rawResultPath=".actual.raw.log"
					local actualResultPath=".actual.log"
					local expectedResultPath=".expected.log"


					if [ ! -e "$expectedResultPath" ]; then
						# If no expected result is found we generate it
						RECORD=1
						echo "$(BO_cecho "[bash.origin.test] No expected test result found. Recording it ..." YELLOW BOLD)"
					fi



					# TODO: Add actual files to ignore rules at git root using bash.origin.git (only if --record)


			        BO_resetLoaded
			        # Run test and record actual result
		
						testRootFile="$(pwd)/main.sh"
						if [ ! -e "$testRootFile" ]; then
							testRootFile="$(pwd)/main"
						fi
						if [ ! -e "$testRootFile" ]; then
							echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Test entry point 'main[.sh]' not found! (pwd: $(pwd))" RED BOLD)"
							exit 1
						fi

						if [[ ! -x "$testRootFile" ]]; then
		        		if [ $RECORD == 0 ]; then
								echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Test entry point '$testRootFile' not executable! Run with '--record' to fix. (pwd: $(pwd))" RED BOLD)"
								exit 1
							else
								echo "Making test entry point '$testRootFile' executable. (pwd: $(pwd))"
								chmod u+x "$testRootFile"
							fi
						fi

						function invokeTest {

							export BO_TEST_PACKAGE_PATH="$__BO_DIR__/.."
							export BO_TEST_RAW_RESULT_PATH="$(pwd)/$rawResultPath"

								# TODO: Write wrapper for 'testRootFile' that will log error message
								#       if exit code not 0 so that test will fail. Currently exit codes are ignored.
				        "$BO_BASH" "$__BO_DIR__/runner.sh" "$testRootFile" 2>&1 | tee "$rawResultPath"

								cp -f "$rawResultPath" "$actualResultPath"


								# Remove sections to be ignored
								sed -i -e '/TEST_MATCH_IGNORE>>>/,/<<<TEST_MATCH_IGNORE/d' "$actualResultPath"
								# cleanup remaining keyworkds in case multiple sections were nested
								sed -i -e "/<<<TEST_MATCH_IGNORE/d" "$actualResultPath"


								# Make paths in result relative

								ownPath=`echo "$(pwd)" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $ownPath"
								sed -i -e "s/$ownPath//g" "$actualResultPath"

								basePath=`echo "$testBaseDir" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $basePath"
								sed -i -e "s/$basePath//g" "$actualResultPath"

								packagesDir=`echo "$BO_PACKAGES_DIR" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $packagesDir"
								sed -i -e "s/$packagesDir//g" "$actualResultPath"

								systemDir=`echo "$BO_SYSTEM_CACHE_DIR" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $systemDir"
								sed -i -e "s/$systemDir//g" "$actualResultPath"

								homePath=`echo "$HOME" | sed 's/\\//\\\\\\//g'`
								[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $homePath"
								sed -i -e "s/$homePath//g" "$actualResultPath"

								if [ -e "$actualResultPath-e" ]; then
										rm "$actualResultPath-e"
								fi
						}

						invokeTest

						if [[ $BO_TEST_FLAG_DEV == 1 ]]; then
							echo "$(BO_cecho "[bash.origin.test] Skip test evaluation. Running in dev mode." YELLOW BOLD)"
						elif [[ $BO_TEST_FLAG_PROFILE == 1 ]]; then
							echo "$(BO_cecho "[bash.origin.test] Skip test evaluation. Running in profile mode." YELLOW BOLD)"
						else

								if [ ! -s "$actualResultPath" ]; then

										echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Test result was empty! Re-running in verbose mode." RED BOLD)"

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
				                echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Expected result for $testName not found at '$expectedResultPath'! Run tests with '--record' once to generate expected result." RED BOLD)"
				                exit 1
				            fi

										if grep -Fxq ">>>SKIP_TEST<<<" "$actualResultPath"; then

						  		      echo "$(BO_cecho "[bash.origin.test] Skipped $testName Test" YELLOW BOLD)"

										else

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

						  		      echo "$(BO_cecho "[bash.origin.test] Successful: $testName" GREEN BOLD)"
										fi
				        else

										echo "[bash.origin.test] Recording test session for $testName in '.expected.log' files."

				            # Keep actual result as expected result
				            cp -f "$actualResultPath" "$expectedResultPath"

				  		      echo "$(BO_cecho "[bash.origin.test] Test result recorded for $testName. Commit changes to git!" YELLOW BOLD)"
				        fi
						fi
				popd > /dev/null

        BO_format "${VERBOSE}" "FOOTER"
    }


		testBaseDir="$(pwd)/$1"
		testName="$2"

		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testBaseDir: $testBaseDir"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testName: $testName"

		if [ ! -d "$testBaseDir" ]; then
				echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Directory '$testBaseDir' not found! (pwd: $(pwd))" RED BOLD)"
				exit 1
		fi


		if echo "$@" | grep -q -Ee '(\$|\s*)--profile(\s*|\$)'; then
			export BO_TEST_FLAG_PROFILE=1
		elif echo "$npm_config_argv" | grep -q -Ee '"--profile"'; then
			export BO_TEST_FLAG_PROFILE=1
		fi
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_FLAG_PROFILE: $BO_TEST_FLAG_PROFILE"

		if echo "$@" | grep -q -Ee '(\$|\s*)--dev(\s*|\$)'; then
			export BO_TEST_FLAG_DEV=1
		elif echo "$npm_config_argv" | grep -q -Ee '"--dev"'; then
			export BO_TEST_FLAG_DEV=1
		fi
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_FLAG_DEV: $BO_TEST_FLAG_DEV"


		pushd "$testBaseDir" > /dev/null

				if [ -z "$BO_PACKAGES_DIR" ]; then
						export BO_PACKAGES_DIR="$(pwd)/.deps"
				fi
				if [ -z "$BO_SYSTEM_CACHE_DIR" ]; then
						export BO_SYSTEM_CACHE_DIR="$BO_PACKAGES_DIR"
				fi

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
						# TODO: If only '.expected.log' files are unclean we ignore them, treat working
						#       directory as clean and add file list to clean below.
						echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Cannot remove all temporary test assets before recording test run because git is not clean!" RED BOLD)"
						exit 1
					fi

					uncleanFiles=$(git clean -d -x -f --dry-run "$testBaseDir")
					if [ ! -z "$uncleanFiles" ]; then
						echo "Unclean files:"
						echo
						echo "$uncleanFiles"
						echo
						read -p "$(BO_cecho "Remove the above files before running test? [y|n]" WHITE BOLD)" -n 1 -r
						echo
						if [[ $REPLY =~ ^[Yy]$ ]]; then
							git clean -d -x -f "$testBaseDir"
						else
							echo "Aborted"
							exit 0
						fi
					fi
				else
					if [[ $BO_TEST_FLAG_DEV == 1 ]]; then
						echo "$(BO_cecho "[bash.origin.test] Skip clean. Running in dev mode." YELLOW BOLD)"
					elif [[ $BO_TEST_FLAG_PROFILE == 1 ]]; then
						echo "$(BO_cecho "[bash.origin.test] Skip clean. Running in profile mode." YELLOW BOLD)"
					else
						if is_pwd_working_tree_clean; then
							git clean -d -x -f "$testBaseDir" > /dev/null
						fi
					fi
				fi

				if [ -z "$testName" ]; then

						[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Look for test root scripts in: $(pwd) / * / main*"

						for mainpath in */main*; do

								if ! echo "$mainpath" | grep -q -Ee '\/main(\.sh)?$'; then
										continue
								fi

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
