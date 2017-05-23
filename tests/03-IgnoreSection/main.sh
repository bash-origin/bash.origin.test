#!/usr/bin/env bash.origin

echo "TEST_MATCH_IGNORE>>>"

# Show that this changing data will not cause a test failure.
date

echo "<<<TEST_MATCH_IGNORE"


echo "TEST_MATCH_IGNORE>>>"
    echo "ignored 1"
    echo "TEST_MATCH_IGNORE>>>"
        echo "ignored 2"
    echo "<<<TEST_MATCH_IGNORE"
    echo "ignored 3"
echo "<<<TEST_MATCH_IGNORE"


echo "OK"
