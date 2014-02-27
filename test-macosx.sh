#!/bin/bash

# This is used in the "Run Script" phase of each of the targets we build,
# if it is set to 1, the resulting binary is run as part of the xcodebuild
export TEST_AUTORUN=1 

xcodebuild -project EtoileUI.xcodeproj -scheme TestEtoileUI
teststatus=$?

xcodebuild -project EtoileUI.xcodeproj -scheme Collage
collagestatus=$?

# printstatus 'message' status
function printstatus {
  if [[ $2 == 0 ]]; then
    echo "(PASS) $1"
  else
    echo "(FAIL) $1"
  fi
}

echo "EtoileUI Tests Summary"
echo "======================"
printstatus TestEtoileUI $teststatus
printstatus Collage $collagestatus

exitstatus=$(( teststatus || collagestatus ))
exit $exitstatus
