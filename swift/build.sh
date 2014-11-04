#!/bin/sh
rm -rf build

# Using Release causes the end framework to have no
# symbols that use generics (so almost everything)
# Last tested: Xcode 6.1.0
CFG="Debug"

xcodebuild -target PromiseKit -configuration $CFG ONLY_ACTIVE_ARCH=NO -sdk iphoneos          clean build
xcodebuild -target PromiseKit -configuration $CFG -arch x86_64 -sdk iphonesimulator clean build

cd build
lipo -create -output foo $CFG-iphoneos/PromiseKit.framework/PromiseKit $CFG-iphonesimulator/PromiseKit.framework/PromiseKit
mv -f foo $CFG-iphoneos/PromiseKit.framework/PromiseKit
mv $CFG-iphonesimulator/PromiseKit.framework/modules/PromiseKit.swiftmodule/* $CFG-iphoneos/PromiseKit.framework/modules/PromiseKit.swiftmodule
mv $CFG-iphoneos/PromiseKit.framework ~/Desktop
