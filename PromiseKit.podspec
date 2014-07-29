Pod::Spec.new do |s|
  preserved =  %w{objc/Private objc/PromiseKit}

  s.name = "PromiseKit"
  s.version = "0.9.13.2"
  s.source = { :git => "https://github.com/mxcl/#{s.name}.git", :tag => s.version }
  s.license = 'MIT'
  s.summary = 'A delightful Promises implementation for iOS and OS X.'

  s.homepage = 'http://promisekit.org'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://promisekit.org'

  s.requires_arc = true
  s.compiler_flags = '-fmodules'

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  
  s.default_subspec = 'defaults'

  s.subspec 'base' do |ss|
    ss.source_files = 'objc/PromiseKit/*.h', 'objc/PromiseKit.{h,m}'
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
  end

  s.subspec 'defaults' do |ss|
    ss.dependency 'PromiseKit/Foundation'
    ss.ios.dependency 'PromiseKit/UIKit'
    ss.ios.dependency 'PromiseKit/UIAnimation'
    ss.dependency 'PromiseKit/timing'
  end

  s.subspec 'private' do |ss|
    ss.source_files = 'objc/Private/PMKManualReference.m'
    ss.preserve_paths = preserved
  end

  s.subspec 'timing' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.ios.source_files = 'objc/PromiseKit/Promise+Timing.h', 'objc/PromiseKit+Timing.m'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_TIMING=1" }
    ss.preserve_paths = preserved
  end

  s.subspec 'Foundation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'objc/Foundation+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+Foundation.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_FOUNDATION=1" }
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
    ss.dependency "ChuzzleKit"
    ss.dependency "OMGHTTPURLRQ"
  end

  s.subspec 'UIKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.ios.source_files = 'objc/UIKit+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+UIKit.h'
    ss.ios.deployment_target = '5.0'
    ss.ios.frameworks = 'UIKit'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_UIKIT=1" }
    ss.preserve_paths = preserved
    ss.weak_framework = 'AssetsLibrary'
  end

  s.subspec 'UIAnimation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.ios.source_files = 'objc/UIView+PromiseKit.m', 'objc/UIKit+PromiseKit.h', 'objc/deprecated/PromiseKit+UIAnimation.h'
    ss.ios.deployment_target = '4.0'
    ss.ios.frameworks = 'UIKit'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_UIANIMATION=1" }
    ss.preserve_paths = preserved
  end

  s.subspec 'CoreLocation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.source_files = 'objc/CoreLocation+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+CoreLocation.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_CORELOCATION=1" }
    ss.frameworks = 'CoreLocation'
    ss.preserve_paths = preserved
  end

  s.subspec 'MapKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'objc/MapKit+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+MapKit.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_MAPKIT=1" }
    ss.frameworks = 'MapKit'
    ss.preserve_paths = preserved
  end

  s.subspec 'Accounts' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'objc/Accounts+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+Accounts.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_ACCOUNTS=1" }
    ss.frameworks = 'Accounts'
    ss.preserve_paths = preserved
  end

  s.subspec 'Social' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'ChuzzleKit'
    ss.source_files = 'objc/Social+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+Social.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_SOCIAL=1" }
    ss.frameworks = 'Social'
    ss.preserve_paths = preserved
  end

  s.subspec 'StoreKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.source_files = 'objc/StoreKit+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+StoreKit.h'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_STOREKIT=1" }
    ss.frameworks = 'StoreKit'
    ss.preserve_paths = preserved
  end

  s.subspec 'AVFoundation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.ios.source_files = 'objc/AVFoundation+PromiseKit.{h,m}', 'objc/deprecated/PromiseKit+AVFoundation.h'
    ss.ios.deployment_target = '5.0'
    ss.ios.frameworks = 'AVFoundation'
    ss.preserve_paths = preserved
  end
end
