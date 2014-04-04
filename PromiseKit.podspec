Pod::Spec.new do |s|
  preserved =  %w{macros.m NSMethodSignatureForBlock.m PromiseKit}

  s.name = "PromiseKit"
  s.version = "0"
  s.requires_arc = true
  s.dependency "ChuzzleKit"
  s.source_files = "PromiseKit/*.h", "PromiseKit.h"

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  s.subspec 'base' do |ss|
    ss.source_files = "PromiseKit.m"
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
  end

  s.subspec 'Foundation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'PromiseKit+Foundation.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_FOUNDATION=1" }
    ss.preserve_paths = preserved
    ss.frameworks = 'Foundation'
  end

  s.subspec 'UIKit' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.ios.source_files = 'PromiseKit+UIKit.{h,m}'
    ss.osx.source_files = ''
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_UIKIT=1" }
    ss.preserve_paths = preserved
    ss.ios.frameworks = 'UIKit'
    ss.ios.deployment_target = '5.0'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.dependency 'PromiseKit/base'
    ss.source_files = 'PromiseKit+CoreLocation.{h,m}'
    ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_CORELOCATION=1" }
    ss.frameworks = 'CoreLocation'
    ss.preserve_paths = preserved
  end
end
