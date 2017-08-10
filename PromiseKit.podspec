Pod::Spec.new do |s|
  s.name = "PromiseKit"

  `xcodebuild -project PromiseKit.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort("No version detected") if $1.nil?
  abort("Not tagged") unless `git tag`.split.include? $1
  s.version = $1

  s.source = {
    :git => "https://github.com/mxcl/#{s.name}.git",
    :tag => s.version,
    :submodules => true
  }

  s.license = 'MIT'
  s.summary = 'Promises for Swift & ObjC.'
  s.homepage = 'http://promisekit.org'
  s.description = 'A thoughtful and complete implementation of promises for iOS, macOS, watchOS and tvOS with first-class support for both Objective-C and Swift.'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://promisekit.org/docs/'
  s.default_subspecs = 'Foundation', 'UIKit', 'QuartzCore'
  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.subspec 'Accounts' do |ss|
    ss.ios.source_files = ss.osx.source_files = 'Extensions/Accounts/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = 'Accounts'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'Alamofire' do |ss|
    ss.source_files = 'Extensions/Alamofire/Sources/*'
    ss.dependency 'Alamofire', '~> 4.0'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.11'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'AddressBook' do |ss|
    ss.ios.source_files = 'Extensions/AddressBook/Sources/*'
    ss.ios.frameworks = 'AddressBook'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'AssetsLibrary' do |ss|
    ss.ios.source_files = 'Extensions/AssetsLibrary/Sources/*'
    ss.ios.frameworks = 'AssetsLibrary'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'AVFoundation' do |ss|
    ss.ios.source_files = 'Extensions/AVFoundation/Sources/*'
    ss.ios.frameworks = 'AVFoundation'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'Bolts' do |ss|
    ss.source_files = 'Extensions/Bolts/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'Bolts', '~> 1.6.0'
  end

  s.subspec 'CloudKit' do |ss|
    ss.source_files = 'Extensions/CloudKit/Sources/*'
    ss.frameworks = 'CloudKit'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'CoreBluetooth' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/CoreBluetooth/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'CoreBluetooth'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'CorePromise' do |ss|
    hh = Dir['Sources/*.h'] - Dir['Sources/*+Private.h']

    cc = Dir['Sources/*.swift'] - ['Sources/SwiftPM.swift']
    cc << 'Sources/{after,AnyPromise,GlobalState,dispatch_promise,hang,join,PMKPromise,when}.m'
    cc += hh
    
    ss.source_files = cc
    ss.public_header_files = hh
    ss.preserve_paths = 'Sources/AnyPromise+Private.h', 'Sources/PMKCallVariadicBlock.m', 'Sources/NSMethodSignatureForBlock.m'
    ss.frameworks = 'Foundation'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.source_files = 'Extensions/CoreLocation/Sources/*'
    ss.watchos.source_files = 'Extensions/CoreLocation/Sources/CLGeocoder*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'
  end

  s.subspec 'EventKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.watchos.source_files = 'Extensions/EventKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.watchos.frameworks = 'EventKit'
    ss.dependency 'PromiseKit/CorePromise'
  end
  
  s.subspec 'Foundation' do |ss|
    ss.source_files = Dir['Extensions/Foundation/Sources/*']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
  end
    
  s.subspec 'MapKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/MapKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'MapKit'
    ss.tvos.deployment_target = '9.2'
    ss.dependency 'PromiseKit/CorePromise'

    # respecify due to CocoaPods bug where specifying any
    # deployment_target on a subspec causes all other platforms
    # to not inherit deployment targets from their parent spec
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
  end

  s.subspec 'MessageUI' do |ss|
    ss.ios.source_files = 'Extensions/MessagesUI/Sources/*'
    ss.ios.frameworks = 'MessageUI'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'OMGHTTPURLRQ' do |ss|
    ss.source_files = 'Extensions/OMGHTTPURLRQ/Sources/*'
    ss.dependency 'PromiseKit/Foundation'
    ss.dependency 'OMGHTTPURLRQ', '~> 3.2'
  end

  s.subspec 'Photos' do |ss|
    ss.ios.source_files = ss.tvos.source_files = ss.osx.source_files = 'Extensions/Photos/Sources/*'
    ss.ios.frameworks = ss.tvos.frameworks = ss.osx.frameworks = 'Photos'
    ss.tvos.deployment_target = '10.0'
    # CocoaPods sucks: can’t enable this until Xcode 9 is released or lint fails
    #ss.osx.deployment_target = '10.13'
    ss.ios.deployment_target = '8.0'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'QuartzCore' do |ss|
    ss.osx.source_files = ss.ios.source_files = ss.tvos.source_files = 'Extensions/QuartzCore/Sources/*'
    ss.osx.frameworks = ss.ios.frameworks = ss.tvos.frameworks = 'QuartzCore'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'Social' do |ss|
    ss.ios.source_files = 'Extensions/Social/Sources/*'
    ss.osx.source_files = Dir['Extensions/Social/Sources/*'] - ['Categories/Social/Sources/*SLComposeViewController+Promise.swift']
    ss.ios.frameworks = ss.osx.frameworks = 'Social'
    ss.dependency 'PromiseKit/Foundation'
  end

  s.subspec 'StoreKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/StoreKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'StoreKit'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'SystemConfiguration' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/SystemConfiguration/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'SystemConfiguration'
    ss.dependency 'PromiseKit/CorePromise'
  end

  picker_cc = 'Extensions/UIKit/Sources/UIImagePickerController+Promise.swift'
  
  s.subspec 'UIKit' do |ss|
    ss.ios.source_files = ss.tvos.source_files = Dir['Extensions/UIKit/Sources/*'] - [picker_cc]
    ss.tvos.frameworks = ss.ios.frameworks = 'UIKit'
    ss.dependency 'PromiseKit/CorePromise'
  end

  s.subspec 'UIImagePickerController' do |ss|
    # Since iOS 10, App Store submissions that contain references to
    # UIImagePickerController (even if unused in 3rd party libraries)
    # are rejected unless an Info.plist key is specified, thus we
    # moved this code to a sub-subspec.
    #
    # This *was* a subspec of UIKit, but bizarrely CocoaPods would
    # include this when specifying *just* UIKit…!

    ss.ios.source_files = picker_cc
    ss.ios.frameworks = 'UIKit'
    ss.ios.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) PMKImagePickerController=1' }
    ss.dependency 'PromiseKit/UIKit'
  end

  s.subspec 'WatchConnectivity' do |ss|
    ss.ios.source_files = ss.watchos.source_files = 'Extensions/WatchConnectivity/Sources/*'
    ss.ios.frameworks = ss.watchos.frameworks = 'WatchConnectivity'
    ss.dependency 'PromiseKit/CorePromise'
  end
end
