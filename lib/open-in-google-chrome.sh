#!/bin/bash

osascript <<EOD
set theURL to "$1"
tell application "Google Chrome"
	if windows = {} then
		make new window
		set URL of (active tab of window 1) to theURL
	else
		make new tab at the end of window 1 with properties {URL:theURL}
	end if
	activate
end tell
EOD
