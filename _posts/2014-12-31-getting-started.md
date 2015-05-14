---
category: docs
layout: default
---

# Getting Started With PromiseKit

The easiest way to get started with PromiseKit is to use [CocoaPods](http://cocoapods.org), a dependency manager for Cocoa libraries like PromiseKit. 

## Step 1: Download CocoaPods

Open the Terminal app (it can be found in *Applications* in the *Utilities* folder), type the following line and then press `enter`:

{% highlight bash %}
sudo gem install cocoapods && pod setup
{% endhighlight %}

You will be prompted for your password.

## Step 2: Create a Podfile

First we must first ensure that our Terminal is open at the correct directory. Ensure that your Xcode project is open, and that it is the *only* open Xcode project. Then type this into Terminal and press `enter`:

{% highlight bash %}
D=$(osascript -e 'tell application "Xcode" to get path of project 1') cd "$D/.."
{% endhighlight %}

Every project that uses CocoaPods must have a `Podfile`: a text file at your project’s root folder that describes the libraries we want to import. Let’s create it:

{% highlight bash %}
touch Podfile && open -e Podfile
{% endhighlight %}

TextEdit will open, in the empty window type:

{% highlight ruby %}
source 'https://github.com/CocoaPods/Specs.git'
pod 'PromiseKit'
{% endhighlight %}

Save the file.

## Step 3: Install Dependencies

Back in Terminal:

{% highlight bash %}
pod install
{% endhighlight %}

CocoaPods will now set up your project to use PromiseKit.

## Step 4: Back to Xcode

From now on your ***must*** open the Xcode Workspace (`xcworkspace`) rather than the Xcode Project (`xcodeproj`) for your project. The following Terminal command will do that for you now:

{% highlight bash %}
osascript -e 'tell application "Xcode" to quit' && open *.xcworkspace
{% endhighlight %}

## Step 5: Using PromiseKit

In `.m` files you want to use promises:

{% highlight objectivec %}
#import <PromiseKit/PromiseKit.h>
{% endhighlight %}

In `.swift` files:

{% highlight swift %}
import PromiseKit
{% endhighlight %}

<hr>

# Advanced CocoaPods

PromiseKit is modulized; if you only want our promise classes and none of our category additions:

{% highlight ruby %}
pod 'PromiseKit/CorePromise'
{% endhighlight %}

Or if you only want some of our categories:

{% highlight ruby %}
pod 'PromiseKit/AVFoundation'
pod 'PromiseKit/Accounts'
pod 'PromiseKit/AddressBook'
pod 'PromiseKit/AssetsLibrary'
pod 'PromiseKit/CloudKit'
pod 'PromiseKit/CoreLocation'
pod 'PromiseKit/Foundation'
pod 'PromiseKit/MapKit'
pod 'PromiseKit/MessagesUI'
pod 'PromiseKit/Photos'
pod 'PromiseKit/QuartzCore'
pod 'PromiseKit/Social'
pod 'PromiseKit/StoreKit'
pod 'PromiseKit/SystemConfiguration'
pod 'PromiseKit/UIKit'
{% endhighlight %}

<aside>
Asking for just the <i>PromiseKit</i> pod gives you the 80% most people want: <code>Promise&lt;T&gt;</code>, <code>AnyPromise</code>, the <i>Foundation</i> additions and the <i>UIKit</i> additions.
</aside>


# Integrating With Carthage

In your `Cartfile`:

{% highlight ruby %}
github "mxcl/PromiseKit"
{% endhighlight %}


# Integrating By Hand

Either:

* Clone PromiseKit and add the xcodeproj to your project. This will build PromiseKit into a framework you can link in your project.

Or:

* Use our [iOS 7 EZ-Bake](https://github.com/PromiseKit/EZiOS7)

It is not recommended to add the sources directly to your application target; it will work, you'll just have to do a bunch of hacks.


# iOS 7 Support

Because of iOS 8 frameworks, you cannot install PromiseKit 2 with CocoaPods *or* Carthage. Thus to install on iOS 7 you must:

 1. `pod "PromiseKit", "~> 1.5"`
 2. Use our [iOS 7 EZ-Bake](https://github.com/PromiseKit/EZiOS7)

Sorry, but it cannot be helped.

# Requirements & Dependencies

PromiseKit will work back to iOS 6, but not with Carthage as Carthage builds frameworks and frameworks only work on iOS 8 and above. The Swift version *will* work on iOS 7, but you cannot use CocoaPods to install it (because CocoaPods will only build frameworks for Swift projects and frameworks only work on iOS 8), you will need to copy the source files into your project and have them compile by hand. This *does* work! But you will need to make sure you copy only what you need (only copy `.swift` files), and if you need the `NSURLConnection` categories, you will still need `OMGHTTPURLRQ`, which you can simply install with CocoaPods, or just copy all the sources in (OMGHTTPURLRQ is much simpler so it’s just 3 `.m` files and 3 `.h` files).

<div><a class="pagination" href="/swift">Next: Specifics Regarding Swift PromiseKit</a></div>
