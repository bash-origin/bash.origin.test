#!/usr/bin/env bash.origin.script

echo "---"

bash.origin.test "$__DIRNAME__/main.js"

echo "---"

BO_run_recent_node "main.js"

echo "---"

echo "OK"
