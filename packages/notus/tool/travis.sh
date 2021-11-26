#!/bin/sh

set -e

pub get

dart format -o none --set-exit-if-changed lib/
dart format -o none --set-exit-if-changed test/

dartanalyzer --fatal-infos --fatal-warnings .

pub run test -r expanded --coverage coverage/
pub run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib

