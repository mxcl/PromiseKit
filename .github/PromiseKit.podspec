Pod::Spec.new do |s|
  s.name = "PromiseKit"

  s.version = '0.0.1'

  s.source = {
    :git => "https://github.com/mxcl/#{s.name}.git",
    :tag => s.version,
    :submodules => true
  }

  s.license = 'MIT'
  s.summary = 'Promises for Swift & ObjC.'
  s.homepage = 'http://mxcl.dev/PromiseKit/'
  s.description = 'A thoughtful and complete implementation of promises for iOS, macOS, watchOS and tvOS with first-class support for both Objective-C and Swift.'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://mxcl.dev/PromiseKit/reference/v6/Classes/Promise.html'
  s.default_subspecs = 'CorePromise', 'UIKit', 'Foundation'
  s.requires_arc = true
  
  s.swift_versions = ['3.1', '3.2', '3.3', '3.4', '4.0', '4.1', '4.2', '4.3', '4.4', '5.0']

  # CocoaPods requires us to specify the root deployment targets
  # even though for us it is nonsense. Our root spec has no
  # sources.
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DPMKCocoaPods',
  }

  s.subspec 'Accounts' do |ss|
    ss.ios.source_files = ss.osx.source_files = 'Extensions/Accounts/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = 'Accounts'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
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
    ss.ios.deployment_target = '8.0'
  end

  s.subspec 'AssetsLibrary' do |ss|
    ss.ios.source_files = 'Extensions/AssetsLibrary/Sources/*'
    ss.ios.frameworks = 'AssetsLibrary'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
  end

  s.subspec 'AVFoundation' do |ss|
    ss.ios.source_files = 'Extensions/AVFoundation/Sources/*'
    ss.ios.frameworks = 'AVFoundation'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
  end

  s.subspec 'Bolts' do |ss|
    ss.source_files = 'Extensions/Bolts/Sources/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'Bolts', '~> 1.9.0'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'CloudKit' do |ss|
    ss.source_files = 'Extensions/CloudKit/Sources/*'
    ss.frameworks = 'CloudKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '10.0'
    ss.osx.deployment_target = '10.12'
    ss.tvos.deployment_target = '10.0'
    ss.watchos.deployment_target = '3.0'
  end

  s.subspec 'CoreBluetooth' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/CoreBluetooth/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'CoreBluetooth'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'CorePromise' do |ss|
    hh = Dir['Sources/*.h'] - Dir['Sources/*+Private.h']

    cc = Dir['Sources/*.swift'] - ['Sources/SwiftPM.swift']
    cc << 'Sources/{after,AnyPromise,GlobalState,dispatch_promise,hang,join,PMKPromise,when,race}.m'
    cc += hh
    
    ss.source_files = cc
    ss.public_header_files = hh
    ss.preserve_paths = 'Sources/AnyPromise+Private.h', 'Sources/PMKCallVariadicBlock.m', 'Sources/NSMethodSignatureForBlock.m'
    ss.frameworks = 'Foundation'
    
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.source_files = 'Extensions/CoreLocation/Sources/*'
    ss.watchos.source_files = 'Extensions/CoreLocation/Sources/CLGeocoder*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'

    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '3.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'EventKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.watchos.source_files = 'Extensions/EventKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.watchos.frameworks = 'EventKit'
    ss.dependency 'PromiseKit/CorePromise'

    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
  end
  
  s.subspec 'Foundation' do |ss|
    ss.source_files = Dir['Extensions/Foundation/Sources/*']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'HealthKit' do |ss|
    ss.source_files = Dir['Extensions/HealthKit/Sources/*']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'HealthKit'
    ss.ios.deployment_target = '9.0'
    ss.watchos.deployment_target = '2.0'
  end

  s.subspec 'HomeKit' do |ss|
    ss.source_files = Dir['Extensions/HomeKit/Sources/*']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'HomeKit'
    ss.ios.deployment_target = '8.0'
    ss.watchos.deployment_target = '3.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'MapKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/MapKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'MapKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.2'
  end

  s.subspec 'MessageUI' do |ss|
    ss.ios.source_files = 'Extensions/MessagesUI/Sources/*'
    ss.ios.frameworks = 'MessageUI'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
  end

  s.subspec 'OMGHTTPURLRQ' do |ss|
    ss.source_files = 'Extensions/OMGHTTPURLRQ/Sources/*'
    ss.dependency 'PromiseKit/Foundation'
    ss.dependency 'OMGHTTPURLRQ', '~> 3.2'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'Photos' do |ss|
    ss.ios.source_files = ss.tvos.source_files = ss.osx.source_files = 'Extensions/Photos/Sources/*'
    ss.ios.frameworks = ss.tvos.frameworks = ss.osx.frameworks = 'Photos'
    ss.dependency 'PromiseKit/CorePromise'
    
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.13'
    ss.tvos.deployment_target = '10.0'
  end

  s.subspec 'QuartzCore' do |ss|
    ss.osx.source_files = ss.ios.source_files = ss.tvos.source_files = 'Extensions/QuartzCore/Sources/*'
    ss.osx.frameworks = ss.ios.frameworks = ss.tvos.frameworks = 'QuartzCore'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'Social' do |ss|
    ss.ios.source_files = 'Extensions/Social/Sources/*'
    ss.osx.source_files = Dir['Extensions/Social/Sources/*'] - ['Categories/Social/Sources/*SLComposeViewController+Promise.swift']
    ss.ios.frameworks = ss.osx.frameworks = 'Social'
    ss.dependency 'PromiseKit/Foundation'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
  end

  s.subspec 'StoreKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/StoreKit/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'StoreKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'SystemConfiguration' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/SystemConfiguration/Sources/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'SystemConfiguration'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
  end

  picker_cc = 'Extensions/UIKit/Sources/UIImagePickerController+Promise.swift'
  
  s.subspec 'UIKit' do |ss|
    ss.ios.source_files = ss.tvos.source_files = Dir['Extensions/UIKit/Sources/*'] - [picker_cc]
    ss.tvos.frameworks = ss.ios.frameworks = 'UIKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.tvos.deployment_target = '9.0'
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
    ss.ios.deployment_target = '8.0'
  end

  s.subspec 'WatchConnectivity' do |ss|
    ss.ios.source_files = ss.watchos.source_files = 'Extensions/WatchConnectivity/Sources/*'
    ss.ios.frameworks = ss.watchos.frameworks = 'WatchConnectivity'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.watchos.deployment_target = '2.0'
  end
end
