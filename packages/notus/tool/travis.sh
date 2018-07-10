#!/bin/sh

set -e

pub get
pub run test -r expanded
dartfmt -n --set-exit-if-changed lib/
dartanalyzer --fatal-infos --fatal-warnings .
pub run test_coverage
