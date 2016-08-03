Pod::Spec.new do |s|
  s.name = "PromiseKit"

  `xcodebuild -project PromiseKit.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort("No version detected") if $1.nil?
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
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Accounts'
  end

  s.subspec 'Alamofire' do |ss|
    ss.source_files = 'Extensions/Alamofire/Sources/*'
    ss.dependency 'Alamofire'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
    ss.ios.deployment_target = '9.0'
    ss.osx.deployment_target = '10.11'
    ss.tvos.deployment_target = '9.0'
    ss.watchos.deployment_target = '2.0'
  end

  s.subspec 'AddressBook' do |ss|
    ss.ios.source_files = 'Extensions/AddressBook/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'AddressBook'
  end

  s.subspec 'AssetsLibrary' do |ss|
    ss.ios.source_files = 'Extensions/AssetsLibrary/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'AssetsLibrary'
  end

  s.subspec 'AVFoundation' do |ss|
    ss.ios.source_files = 'Extensions/AVFoundation/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'AVFoundation'
  end

  s.subspec 'Bolts' do |ss|
    ss.source_files = 'Extensions/Bolts/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'Bolts', '~> 1.6.0'
  end

  s.subspec 'CloudKit' do |ss|
    ss.source_files = 'Extensions/CloudKit/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CloudKit'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
  end

  s.subspec 'CoreBluetooth' do |ss|
    ss.ios.source_files = ss.osx.source_files = 'Extensions/CoreBluetooth/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreBluetooth'
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
    ss.ios.source_files = 'Extensions/CoreLocation/Sources/*'
    ss.osx.source_files = 'Extensions/CoreLocation/Sources/*'
    ss.watchos.source_files = 'Extensions/CoreLocation/Sources/CLGeocoder*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'
  end

  s.subspec 'EventKit' do |ss|
    ss.ios.source_files = 'Extensions/EventKit/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'EventKit'
  end
  
  s.subspec 'Foundation' do |ss|
    base_files = Dir['Extensions/Foundation/Sources/*']
    nstask_files = Dir['Extensions/Foundation/Sources/*NSTask*']
    base_files -= nstask_files
  
    ss.ios.source_files = base_files
    ss.osx.source_files = base_files + nstask_files
    ss.watchos.source_files = base_files

    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
  end
  
  s.subspec 'OMGHTTPURLRQ' do |ss|
    ss.source_files = 'Extensions/OMGHTTPURLRQ/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'OMGHTTPURLRQ', '~> 3.2'
    ss.frameworks = 'Foundation'
  end
  
  s.subspec 'MapKit' do |ss|
    ss.ios.source_files = 'Extensions/MapKit/Sources/*'
    ss.osx.source_files = 'Extensions/MapKit/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'MapKit'
  end

  s.subspec 'MessageUI' do |ss|
    ss.ios.source_files = 'Extensions/MessageUI/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'MessageUI'
  end

  s.subspec 'Photos' do |ss|
    ss.ios.source_files = 'Extensions/Photos/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'Photos'
  end

  s.subspec 'QuartzCore' do |ss|
    ss.ios.source_files = 'Extensions/QuartzCore/Sources/*'
	ss.osx.source_files = 'Extensions/QuartzCore/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = ss.osx.frameworks = 'QuartzCore'
  end

  s.subspec 'Social' do |ss|
    ss.ios.source_files = 'Extensions/Social/Sources/*'
    ss.osx.source_files = Dir['Extensions/Social/*'] - ['Categories/Social/Sources/*SLComposeViewController+Promise.swift']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Social'
  end

  s.subspec 'StoreKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/StoreKit/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'StoreKit'
  end

  s.subspec 'SystemConfiguration' do |ss|
    ss.ios.source_files = ss.osx.source_files = 'Extensions/SystemConfiguration/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'SystemConfiguration'
  end

  s.subspec 'UIKit' do |ss|
    deprecated_files = Dir['Extensions/UIKit/UIActionSheet*', 'Categories/UIKit/Sources/*UIAlertView*']
    
    ss.ios.source_files = Dir['Extensions/UIKit/Sources/*'] - deprecated_files
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'UIKit'
  end

  s.subspec 'WatchConnectivity' do |ss|
    ss.source_files = 'Extensions/WatchConnectivity/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'WatchConnectivity'
    ss.ios.deployment_target = '8.0'
    ss.watchos.deployment_target = '2.0'
  end
end
