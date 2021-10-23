#!/bin/sh

set -e

flutter test || $TRAVIS_BUILD_DIR/flutter/bin/flutter test

dart format -o none --set-exit-if-changed lib/
dart format -o none --set-exit-if-changed test/
