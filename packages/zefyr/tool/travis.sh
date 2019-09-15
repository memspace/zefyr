#!/bin/sh

set -e

$TRAVIS_BUILD_DIR/flutter/bin/flutter test

dartfmt -n --set-exit-if-changed lib/
dartfmt -n --set-exit-if-changed test/