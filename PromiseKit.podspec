Pod::Spec.new do |s|
  preserved =  %w{Private PromiseKit}

  s.name = "PromiseKit"
  s.version = "0.9.7.5"
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

  s.subspec 'base' do |ss|
    ss.source_files = 'PromiseKit/*.h', 'PromiseKit.{h,m}'
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
  end

  s.subspec 'private' do |ss|
    ss.source_files = 'Private/PMKManualReference.m'
    ss.preserve_paths = preserved
  end

  s.subspec 'Foundation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'PromiseKit+Foundation.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_FOUNDATION=1" }
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
    ss.dependency "ChuzzleKit"
  end

  s.subspec 'UIKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.ios.source_files = 'PromiseKit+UIKit.{h,m}'
    ss.ios.deployment_target = '5.0'
    ss.ios.frameworks = 'UIKit'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_UIKIT=1" }
    ss.preserve_paths = preserved
    ss.weak_framework = 'AssetsLibrary'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.source_files = 'PromiseKit+CoreLocation.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_CORELOCATION=1" }
    ss.frameworks = 'CoreLocation'
    ss.preserve_paths = preserved
  end

  s.subspec 'MapKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'PromiseKit+MapKit.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_MAPKIT=1" }
    ss.frameworks = 'MapKit'
    ss.preserve_paths = preserved
  end

  s.subspec 'Social' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'PromiseKit+Social.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_SOCIAL=1" }
    ss.frameworks = 'Social', 'Accounts'
    ss.preserve_paths = preserved
  end

  s.subspec 'StoreKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.dependency 'PromiseKit/private'
    ss.source_files = 'PromiseKit+StoreKit.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_STOREKIT=1" }
    ss.frameworks = 'StoreKit'
    ss.preserve_paths = preserved
  end
end
