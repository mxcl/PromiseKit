Pod::Spec.new do |s|
  s.name = "PromiseKit"

  s.version = ENV['PMKVersion'] || '7.999.0'

  s.source = {
    :git => "https://github.com/mxcl/#{s.name}.git",
    :tag => s.version
  }

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DPMKCocoaPods',
  }

  s.license = 'MIT'
  s.summary = 'Promises for Swift & ObjC.'
  s.homepage = 'http://mxcl.dev/PromiseKit/'
  s.description = 'A thoughtful and complete implementation of promises for iOS, macOS, watchOS and tvOS with first-class support for both Objective-C and Swift.'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://mxcl.dev/PromiseKit/reference/v7/Classes/Promise.html'
  s.default_subspecs = 'CorePromise', 'Foundation'
  s.requires_arc = true

  s.swift_versions = ['5.3', '5.4']

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '9.0'

  s.subspec 'CloudKit' do |ss|
    ss.source_files = 'Sources/PMKCloudKit/*'
    ss.frameworks = 'CloudKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '10.0'
    ss.osx.deployment_target = '10.12'
    ss.tvos.deployment_target = '10.0'
    ss.watchos.deployment_target = '3.0'
  end

  s.subspec 'CorePromise' do |ss|
    ss.source_files = 'Sources/PromiseKit/**/*'
    ss.frameworks = 'Foundation'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.source_files = 'Sources/PMKCoreLocation/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'

    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '3.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'Foundation' do |ss|
    ss.source_files = 'Sources/PMKFoundation/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'HealthKit' do |ss|
    ss.source_files = 'Sources/PMKHealthKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'HealthKit'
    ss.ios.deployment_target = '9.0'
    ss.watchos.deployment_target = '2.0'
  end

  s.subspec 'HomeKit' do |ss|
    ss.source_files = 'Sources/PMKHomeKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'HomeKit'
    ss.ios.deployment_target = '8.0'
    ss.watchos.deployment_target = '3.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'MapKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Sources/PMKMapKit/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'MapKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.2'
  end

  s.subspec 'Photos' do |ss|
    ss.ios.source_files = ss.tvos.source_files = ss.osx.source_files = 'Sources/PMKPhotos/*'
    ss.ios.frameworks = ss.tvos.frameworks = ss.osx.frameworks = 'Photos'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.13'
    ss.tvos.deployment_target = '10.0'
  end

  s.subspec 'StoreKit' do |ss|
    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Sources/PMKStoreKit/*'
    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'StoreKit'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
  end
end
