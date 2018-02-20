#!/bin/bash

set -o pipefail # do what we want with pipes
set -e # exit on error
set -x # echo commands

case $PLAT in
iOS|tvOS|macOS)
  xcodebuild -scheme PromiseKit SWIFT_VERSION=$SWFT -destination "$DST" test;;
*)
  ;;
esac
