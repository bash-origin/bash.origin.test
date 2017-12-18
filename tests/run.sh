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

[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] script args: $@"
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
if [ -z "${BO_LOADED}" ] || ! declare -F BO_echo; then
		BO_LOADED=
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


		export BO_ALLOW_DOWNLOADS=1
		export BO_ALLOW_INSTALLS=1


		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] init()"


		# TODO: Optionally source profile in runner? Move this to runner.
		# Source profile to get access to path variables
		# TODO: Save all ENV variables except for PATH?
		#BO_ENABLE_SOURCE_PROFILE=1
		#BO_sourceProfile


		# We only run this once in the top test shell.
		if [ -z "$BO_TEST_BASE_DIR" ]; then
			# Ensure 'bash.origin' is on path (will be place in NVM bin dir`)
			# TODO: Ensure 'bash.origin' bin using own helper.
			# NOTE: We also ensure 'node' here to ensure we are using a consistent version.
			BO_ensure_node
		fi


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


					if [ ! -e "$expectedResultPath" ] && [[ $BO_TEST_FLAG_DEV != 1 ]]; then
						# If no expected result is found we generate it
						export BO_TEST_FLAG_RECORD=1
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

							testRootFile="$(pwd)/main.js"
							if [ ! -e "$testRootFile" ]; then
								echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Test entry point 'main[.sh|.js]' not found! (pwd: $(pwd))" RED BOLD)"
								exit 1
							fi
						fi

						if [[ ! -x "$testRootFile" ]]; then
		        			if [[ $BO_TEST_FLAG_RECORD != 1 ]] && [[ $BO_TEST_FLAG_DEV != 1 ]]; then
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

							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testRootFile: $testRootFile"
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] rawResultPath: $rawResultPath"

							BO_TEST_RUNNER_IMPL run "$testRootFile" "$rawResultPath"

							cp -f "$rawResultPath" "$actualResultPath"


							# Remove sections to be ignored
							#sed -i -e '/TEST_MATCH_IGNORE>>>/,/<<<TEST_MATCH_IGNORE/d' "$actualResultPath"
							# cleanup remaining keyworkds in case multiple sections were nested
							#sed -i -e "/<<<TEST_MATCH_IGNORE/d" "$actualResultPath"
							# TODO: Support ignoring parts of a single line.
							BO_run_recent_node --eval '
								const FS = require("fs");
								var lines = FS.readFileSync("'$actualResultPath'", "utf8").split("\n");
								var ignoring = 0;
								var dynamicIgnoreRules = [];
								lines = lines.filter(function (line) {

									//>>>TEST_IGNORE_LINE:<REG_EXP><<<
									if (/^>>>TEST_IGNORE_LINE:(.+?)<<<$/.test(line)) {
										dynamicIgnoreRules.push(
											new RegExp(line.match(/^>>>TEST_IGNORE_LINE:(.+?)<<<$/)[1])
										);
									}
									if (dynamicIgnoreRules.length > 0) {
										var ignore = false;
										dynamicIgnoreRules.forEach(function (re) {
											if (ignore) return;
											if (re.test(line)) {
												ignore = true;
											}
										});
										if (ignore) {
											return false;
										}
									}

									if (/TEST_MATCH_IGNORE>>>/.test(line)) {
										ignoring += 1;
										return false;
									} else
									if (/<<<TEST_MATCH_IGNORE/.test(line)) {
										ignoring -= 1;
										return false;
									} else
									if (ignoring > 0) {
										return false;
									}
									return true;
								});
								FS.writeFileSync("'$actualResultPath'", lines.join("\n"), "utf8");
							'

							# Make paths in result relative
							ownPath=`echo "$(pwd)" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $ownPath"
							sed -i -e "s/$ownPath/TeStLoCaLiZeD/g" "$actualResultPath"

							basePath=`echo "$testBaseDir" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $basePath"
							sed -i -e "s/$basePath/TeStLoCaLiZeD/g" "$actualResultPath"

							packagesDir=`echo "$BO_PACKAGES_DIR" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $packagesDir"
							sed -i -e "s/$packagesDir/TeStLoCaLiZeD/g" "$actualResultPath"

							systemDir=`echo "$BO_SYSTEM_CACHE_DIR" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $systemDir"
							sed -i -e "s/$systemDir/TeStLoCaLiZeD/g" "$actualResultPath"

							homePath=`echo "$HOME" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $homePath"
							sed -i -e "s/$homePath/TeStLoCaLiZeD/g" "$actualResultPath"

							pkgPath=`echo "$BO_TEST_HOST_PACKAGE_BASE_DIR" | sed 's/\\//\\\\\\//g'`
							[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Replacing in result: $pkgPath"
							sed -i -e "s/$pkgPath/TeStLoCaLiZeD/g" "$actualResultPath"

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

								echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Test result was empty!" RED BOLD)"

								# TODO: If no terminal attached we should exit
								read -p "$(BO_cecho "[bash.origin.test][run.sh] Press any key to re-run in verbose mode?" RED BOLD)" -n 1 -r
								echo

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


							if [[ $BO_TEST_FLAG_RECORD != 1 ]]; then

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

										# TODO: If no terminal attached we should exit?
										# If we are not on CircleCI we ask user if diffs should be shown.
										# TODO: Detect more CI environments.
										if [ -z "$CIRCLE_BRANCH" ]; then
											# Not on CI server so we ask user.
											echo "$(BO_cecho "|" RED BOLD)"
											read -p "$(BO_cecho "| Press any key to show ACTUAL & EXPECTED results as well as DIFF?" RED BOLD)" -n 1 -r
											echo "$(BO_cecho "|" RED BOLD)"
										fi

										#echo "$(BO_cecho "| ########## ACTUAL : $rawResultPath >>>" RED BOLD)"
										#cat "$rawResultPath"
										echo "$(BO_cecho "| ########## ACTUAL : $actualResultPath >>>" RED BOLD)"
										cat "$actualResultPath"
										echo "$(BO_cecho "| ########## EXPECTED : $expectedResultPath >>>" RED BOLD)"
										cat "$expectedResultPath"
										echo "$(BO_cecho "| ########## DIFF >>>" RED BOLD)"
										set +e
										# TODO: Show coloured diff.
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
								exit 0
				        	fi
						fi
				popd > /dev/null

        BO_format "${VERBOSE}" "FOOTER"
    }


		BO_TEST_HOST_PACKAGE_BASE_DIR="$(pwd)"


		BO_parse_args "ARGS" "$@"

		if [ ! -z "$ARGS_OPT_init" ]; then

			testBaseDir="$(pwd)/$1"

			BO_requireModule "$__BO_DIR__/../lib/init.sh" as "BO_TEST_INIT_IMPL"
			BO_TEST_INIT_IMPL init "$testBaseDir/01-HelloWorld"

			testName="01"
		else

			if [ -f "$1" ] && [ -z "$2" ]; then

				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Scan head for '#!/usr/bin/env bash.origin.test via ...'"

				if [[ "$(head -1 "$1")" == "#!/usr/bin/env bash.origin.test via"* ]] ; then
					testRunnerUri="$(head -1 "$1" | perl -pe "s/^.+ via (.+)\$/\$1/")"

					[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testRunnerUri: $testRunnerUri"

					testRunnerPath="$__BO_DIR__/../lib/runners/$(echo "$testRunnerUri" | perl -pe "s/\//~/g").sh"

					[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testRunnerPath: $testRunnerPath"

					BO_requireModule "$testRunnerPath" as "BO_TEST_RUNNER_IMPL"

					[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_BASE_DIR: $BO_TEST_BASE_DIR"

					if [ ! -z "$BO_TEST_BASE_DIR" ]; then
						testBaseDir="$BO_TEST_BASE_DIR"
						testPath="$1"
					else
						testBaseDir="$(dirname $1)"
						testPath="$1"
						if [ "${testPath:0:1}" != "/" ]; then
							testPath="$(pwd)/${testPath}"
						else
							testPath="../$1"
						fi
					fi
				else
					echo "$(BO_cecho "[bash.origin.test] Test file $1 does not have a '#!/usr/bin/env bash.origin.test via ...' header!" RED BOLD)"
					exit 1
				fi
			else
				testBaseDir="$(pwd)/$1"
				testName="$2"
			fi
		fi

		if ! declare -F BO_TEST_RUNNER_IMPL > /dev/null; then
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Load default 'BO_TEST_RUNNER_IMPL'"
			BO_requireModule "$__BO_DIR__/../lib/runners/bash.origin.sh" as "BO_TEST_RUNNER_IMPL"
		fi

		#[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_RUNNER_IMPL: $BO_TEST_RUNNER_IMPL"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testBaseDir: $testBaseDir"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testName: $testName"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testPath: $testPath"


		if [ ! -d "$testBaseDir" ]; then
			echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Directory '$testBaseDir' not found! (pwd: $(pwd))" RED BOLD)"
			exit 1
		fi


		export BO_TEST_BASE_DIR="$testBaseDir"
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_BASE_DIR: $BO_TEST_BASE_DIR"


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

		if echo "$@" | grep -q -Ee '(\$|\s*)--inspect(\s*|\$)'; then
			export BO_TEST_FLAG_INSPECT=1
		elif echo "$npm_config_argv" | grep -q -Ee '"--inspect"'; then
			export BO_TEST_FLAG_INSPECT=1
		fi
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_FLAG_INSPECT: $BO_TEST_FLAG_INSPECT"

		if echo "$@" | grep -q -Ee '(\$|\s*)--record(\s*|\$)'; then
			export BO_TEST_FLAG_RECORD=1
		elif echo "$npm_config_argv" | grep -q -Ee '"--record"'; then
			export BO_TEST_FLAG_RECORD=1
		fi
		[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_TEST_FLAG_RECORD: $BO_TEST_FLAG_RECORD"


		pushd "$testBaseDir" > /dev/null

			if [ -z "$BO_PACKAGES_DIR" ]; then
				export BO_PACKAGES_DIR="$(pwd)/.deps"
			fi
			if [ -z "$BO_SYSTEM_CACHE_DIR" ]; then
				export BO_SYSTEM_CACHE_DIR="$BO_PACKAGES_DIR"
			fi

			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_PACKAGES_DIR: $BO_PACKAGES_DIR"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_SYSTEM_CACHE_DIR: $BO_SYSTEM_CACHE_DIR"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] BO_BASH: $BO_BASH"

			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] pwd: $(pwd)"
			[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] testPath: $testPath"

			if [ -e "$testPath" ]; then

				[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] run BO_TEST_RUNNER_IMPL for testPath: $testPath"

				BO_TEST_RUNNER_IMPL run "$testPath"

			else

				if [[ $BO_TEST_FLAG_RECORD == 1 ]]; then
					if ! is_pwd_working_tree_clean; then
						# TODO: If only '.expected.log' files are unclean we ignore them, treat working
						#       directory as clean and add file list to clean below.
						echo >&2 "$(BO_cecho "[bash.origin.test][run.sh] ERROR: Cannot remove all temporary test assets before recording test run because git is not clean!" RED BOLD)"
						exit 1
					fi

					if [[ $BO_TEST_SKIP_CLEAN != 1 ]]; then
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
								echo "Ignoring files. Continuing ..."
							fi
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
					# Run all tests

					[ -z "$BO_VERBOSE" ] || echo "[bash.origin.test][run.sh] Look for test root scripts in: $(pwd)/*/main*"

					for mainpath in */main*; do

						if ! echo "$mainpath" | grep -q -Ee '\/main(\.sh|\.js)?$'; then
							continue
						fi

						runTest "$(dirname "$mainpath")"
					done
				else
					# Run specified test

					# source https://unix.stackexchange.com/a/220196
					if [ -d "$testName-"* ] 2>/dev/null; then
						pushd "$testName-"* > /dev/null
							testName="$(basename $(pwd))"
						popd > /dev/null
						runTest "${testName}"
					else
						set +e
						ls "$testName-"* >/dev/null 2>&1
						if [ $? -ne 0 ]; then
							BO_exit_error "Cannot find test with prefix '$testName-' in '$(pwd)'"
						fi
						BO_exit_error "Found more than one test with prefix '$testName-' in '$(pwd)'"
					fi
				fi
			fi
		popd > /dev/null
}
init "$@"


#	local runLogPath
#	if [ ! -z "${CIRCLE_ARTIFACTS}" ]; then
#		runLogPath="${CIRCLE_ARTIFACTS}/tests.run.bash.log"
#	else
#		runLogPath="tests/.run.bash.log"
#	fi
	# TODO: Use NodeJS to split output to log and stdout so we can stream to remote socket
	#       and preserve escape characters.
#	BO_sourcePrototype "${__BO_DIR__}/run.sh" Run 2>&1 | tee "$runLogPath"

	# TODO: Write test result to $CIRCLE_TEST_REPORTS/tests.run.result.xml
	#<?xml version="1.0" encoding="UTF-8"?>
	#<testsuite>
	#  <!-- if your classname does not include a dot, the package defaults to "(root)" -->
	#  <testcase name="my testcase" classname="my package.my classname" time="29">
	#    <!-- If the test didn't pass, specify ONE of the following 3 cases -->
	#    <!-- option 1 --> <skipped />
	#    <!-- option 2 --> <failure message="my failure message">my stack trace</failure>
	#    <!-- option 3 --> <error message="my error message">my crash report</error>
	#    <system-out>my STDOUT dump</system-out>
	#    <system-err>my STDERR dump</system-err>
	#  </testcase>
	#</testsuite>

	# TODO: Get latest build artifacts and make available publickly
	#curl https://circleci.com/api/v1.1/me?circle-token=
	#curl https://circleci.com/api/v1.1/project/github/0ink/codeblock.js?circle-token=
	#curl https://circleci.com/api/v1.1/project/github/0ink/codeblock.js/latest/artifacts?circle-token=
