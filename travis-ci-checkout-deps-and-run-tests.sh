#!/bin/bash

# check out dependencies in the parent directory
cd ..

if [ -e "EtoileFoundation" ]
then
  echo "You already have EtoileFoundation in the parent directory of EtoileUI. This script is meant to be run in a fresh "
  echo "checkout of EtoileUI on a continuous integration server."
  exit 1
fi

git clone https://github.com/etoile/UnitKit.git
cd UnitKit
sudo xcodebuild -target ukrun -configuration Release clean install
cd ..

git clone https://github.com/etoile/trunk/EtoileFoundation.git
git clone https://github.com/etoile/trunk/CoreObject.git
git clone https://github.com/etoile/trunk/IconKit.git

# build & run the tests
cd EtoileUI
./test-macosx.sh
