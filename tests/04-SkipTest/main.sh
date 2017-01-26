#!/usr/bin/env bash.origin

# Show that this changing data will not cause a test failure.
date

echo ">>>SKIP_TEST<<<"

# Show that a non-0 exit code will not cause a test failure.
exit 1
