#!/bin/sh

set -e

cd "packages/$1"
./tool/travis.sh
