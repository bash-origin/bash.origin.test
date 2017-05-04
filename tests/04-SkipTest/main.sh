#!/usr/bin/env bash.origin

if [ $BO_TEST_FLAG_RECORD == 1 ]; then
    echo "Wed 25 Jan 2017 19:20:40 PST"
else
    # Show that this changing data will not cause a test failure.
    date
fi

echo ">>>SKIP_TEST<<<"

# Show that a non-0 exit code will not cause a test failure.
exit 1
