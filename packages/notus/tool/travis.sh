#!/bin/sh

set -e

pub get
pub run test -r expanded
dartfmt -n --set-exit-if-changed lib/
dartfmt -n --set-exit-if-changed test/
dartanalyzer --fatal-infos --fatal-warnings .
pub run test_coverage
