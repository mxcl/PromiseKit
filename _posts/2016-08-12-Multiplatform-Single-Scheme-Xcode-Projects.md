---
layout: default
---

# Multiplatform, Single-scheme Xcode Projects

<blockquote>{{ page.date | date: '%B %d, %Y' }}</blockquote>

Apple-platform framework authors know the special hell that is this:

![multischeme]

It was once bearable–before watchOS and tvOS—then you only had to maintain two
schemes, one if your library used UIKit.

Maintaining multiple schemes that only differ by targeted platform would not be a major pain if it wasn't for tests. Tests can only (directly) target a single scheme’s framework, so if you want to have your tests run on all platforms then you need four test targets too.

In reality this is just a maintenance burden and a tedious one at that, so we all just picked a single platform and targeted that.

Do our frameworks work correctly on the three other platforms? We hope so.

This has never been acceptable to me, and often I would lay awake at night worried that somewhere out there my code was failing on someone’s watchOS app.

Not to mention that being absolutely sure that all four targets have the exact same settings is time consuming. And if it is time consuming that means we either automate it (personally I could not be bothered to write such a script) or it involved crossing fingers.

## Anyway I'll get to the point

I downloaded [PMHTTP] the other day and when I opened its project I noticed it only had one scheme. At first I figured they only supported iOS, which happens, but when I opened the scheme platform selector I saw this:

![multiplatform]

Tentatively I ran the macOS tests, they passed. I selected tvOS and ran the tests again. The tvOS simulator appeared and the tests ran.

**They passed**.

## How did they do this magic?

The supported platforms setting looked different:

![supported-platforms]

Obvious, but I had never tried setting more than one platform here. I quickly opened `PromiseKit.xcodeproj` and tried to do the same. Naive clicks did nothing, you have to click *“Other”* and then add the following one by one:

* `macosx` *not macOS or OSX*
* `iphoneos` *not iOS*
* `appletvos` *not tvos*
* `watchos`
* `appletvsimulator`
* `iphonesimulator`
* `watchsimulator`

Since you want these for all targets, *including test targets*, I suggest adding them to the Project’s settings and then pressing backspace on each target’s supported platforms so it
inherits. Saves you effort.

Now set `TARGETED_DEVICE_FAMILY` to `1,2,3,4`. I don’t know *why* this is required, but otherwise the watchOS and tvOS platforms fail to appear in the device selector. And, annoyingly, the only way you can set this (that I could determine) is to edit the `project.pbxproj` file in a text-editor.

You will probably need to set a deployment target for each platform (use the Build Settings screen).

That’s it!

## That’s not it

Yes, well. There are caveats and consequences.

Firstly, I don't think this is officially supported. I could not find any documentation about it.

However, I think it is worth it. My travis is finally testing all platforms.

Thirdly, well actually Travis is not testing all platforms, did you know watchOS
doesn't have XCTest? The best you can do is have Travis simply build your scheme for watchOS.

Fourthly you will likely have issues with `@rpath`s in your tests. And these issues will manifest by Xcode appearing to succeed when testing, but then if you go to your test navigator you will see no tests ran, and then if you go to the test log you will see “timeout waiting for bootstrap” or some such. There's a log you can read if you can be bothered to copy and paste the filename it provides and open it into an editor.

Fifthly your tests must be cross-platform too. UITests are platform specific. You may have subtle platform specific quirks in your existing tests, but these will be easy fixes.

I also don’t know if it works on Xcode 7.

## Fixing `@rpath`

I'm no stranger to these sorts of problems, fortunately, (sadly); the problem manifests because iOS and macOS have different test-bundle layouts, so your framework will be placed in different places in each, thus you have to tell your tests to look in different places for each. The easiest way is just to set the test rpaths to:

    @loader_path/Frameworks
    @executable_path/Frameworks
    @loader_path/../Frameworks
    @executable_path/../Frameworks

## Travis configuration

Travis does not support this configuration by default, here’s my `travis.yml`:

```yaml
language: objective-c
osx_image: xcode8

env:
  - ACTION=test  PLATFORM=Mac     DESTINATION='platform=OS X'
  - ACTION=test  PLATFORM=iOS     DESTINATION='platform=iOS Simulator,name=iPhone 6S'
  - ACTION=build PLATFORM=watchOS DESTINATION='platform=watchOS Simulator,name=Apple Watch - 38mm'
  - ACTION=test  PLATFORM=tvOS    DESTINATION='platform=tvOS Simulator,name=Apple TV 1080p'

install:
  - test -f Cartfile* && carthage bootstrap --platform $PLATFORM

script:
  - set -o pipefail && xcodebuild -scheme PromiseKit -destination "$DESTINATION" $ACTION | xcpretty
```

> Note, the watchOS build will fail unless the build section of your scheme has the all but the build for testing action unchecked for your test targets.

## Do you have Carthage dependencies?

In which case you have to do more. I suggest looking at the example `xcodeproj` files I provide.

## Should you do this?

If you have an app, probably not, but if you have a framework, I think you should. I discovered numerous holes in my tests and even some compilation issues. Quality, robustness and just-works are key to open source projects. Improve yours.

## Examples:

* [https://github.com/mxcl/PromiseKit](https://github.com/mxcl/PromiseKit/tree/swift-3.0)
* [https://github.com/mxcl/OMGHTTPURLRQ](https://github.com/mxcl/OMGHTTPURLRQ)
* [https://github.com/postmates/PMHTTP](https://github.com/postmates/PMHTTP)

# Update 1

Mike Weller of Bloomberg London wrote to me saying the following:

> Hi there, RE: your article (which is great btw, we're now using this technique) - we ran into an issue with running `xcodebuild archive` on a project after adding one of these multi-platform frameworks as a build-from-source subproject. xcodebuild would fail with "The run destination My Mac is not valid for Archiving the scheme ..."

> Seems xcodebuild gets confused about which platform to build for and in our case no longer defaulted to iOS. The fix for us was pretty simple: add `-destination generic/platform=iOS`. Thought you might want to know in case you ever update the article; might be worth mentioning the need for an explicit destination in some cases.


[multischeme]: ../../../../public/img/news/multischeme.png
[multiplatform]: ../../../../public/img/news/multiplatform.png
[supported-platforms]: ../../../../public/img/news/supported-platforms.png
[PMHTTP]: https://github.com/postmates/PMHTTP
