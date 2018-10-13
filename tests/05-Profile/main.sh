#!/usr/bin/env bash

echo "TEST_MATCH_IGNORE>>>"

BO_TEST_BASE_DIR= bash.origin.test tests 01 --profile --dev

echo "<<<TEST_MATCH_IGNORE"

echo "OK"
