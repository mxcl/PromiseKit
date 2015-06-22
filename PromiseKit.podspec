Pod::Spec.new do |s|
  s.name = "PromiseKit"

  `xcodebuild -project PromiseKit.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort("No version detected") if $1.nil?
  s.version = $1

  s.source = { :git => "https://github.com/mxcl/#{s.name}.git", :tag => s.version }
  s.license = { :type => 'MIT', :text => '@see README' }
  s.summary = 'A delightful Promises implementation for iOS and OS X.'
  s.homepage = 'http://promisekit.org'
  s.description = 'UIActionSheet UIAlertView CLLocationManager MFMailComposeViewController ACAccountStore StoreKit SKRequest SKProductRequest blocks'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://promisekit.org/introduction/'
  s.default_subspecs = 'Foundation', 'UIKit', 'QuartzCore'
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.module_map = 'Sources/PMK.modulemap'
  s.xcconfig = { 'SWIFT_INSTALL_OBJC_HEADER' => 'NO' }

  s.subspec 'Accounts' do |ss|
    ss.source_files = 'Categories/Accounts/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Accounts'
  end

  s.subspec 'AddressBook' do |ss|
    ss.ios.source_files = 'Categories/AddressBook/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'AddressBook'
  end

  s.subspec 'AssetsLibrary' do |ss|
    ss.ios.source_files = 'Categories/AssetsLibrary/*'
    ss.dependency 'PromiseKit/UIKit'
    ss.ios.frameworks = 'AssetsLibrary'
  end

  s.subspec 'AVFoundation' do |ss|
    ss.ios.source_files = 'Categories/AVFoundation/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'AVFoundation'
  end

  s.subspec 'CloudKit' do |ss|
    ss.source_files = 'Categories/CloudKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CloudKit'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
  end

  s.subspec 'CorePromise' do |ss|
    hh = Dir['Sources/*.h'] - Dir['Sources/*+Private.h']
    
    ss.source_files = 'Sources/*.{swift}', 'Sources/{after,AnyPromise,dispatch_promise,hang,join,PMKPromise,when}.m', *hh
    ss.public_header_files = hh
    ss.preserve_paths = 'Sources/AnyPromise+Private.h', 'Sources/PMKCallVariadicBlock.m', 'Sources/NSMethodSignatureForBlock.m'
    ss.frameworks = 'Foundation'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.source_files = 'Categories/CoreLocation/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'
  end
  
  s.subspec 'Foundation' do |ss|
    ss.ios.source_files = Dir['Categories/Foundation/*'] - Dir['Categories/Foundation/NSTask*']
    ss.osx.source_files = 'Categories/Foundation/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.dependency 'OMGHTTPURLRQ', '~> 2.1.3'
    ss.frameworks = 'Foundation'
  end

  s.subspec 'MapKit' do |ss|
    ss.source_files = 'Categories/MapKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'MapKit'
  end

  s.subspec 'MessageUI' do |ss|
    ss.ios.source_files = 'Categories/MessageUI/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'MessageUI'
  end

  s.subspec 'Photos' do |ss|
    ss.ios.source_files = 'Categories/Photos/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'Photos'
  end

  s.subspec 'QuartzCore' do |ss|
    ss.source_files = 'Categories/QuartzCore/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'QuartzCore'
  end

  s.subspec 'Social' do |ss|
    ss.ios.source_files = 'Categories/Social/*'
    ss.osx.source_files = Dir['Categories/Social/*'] - ['Categories/Social/SLComposeViewController+Promise.swift']
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'Social'
  end

  s.subspec 'StoreKit' do |ss|
    ss.source_files = 'Categories/StoreKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'StoreKit'
  end

  s.subspec 'SystemConfiguration' do |ss|
    ss.source_files = 'Categories/SystemConfiguration/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.frameworks = 'SystemConfiguration'
  end

  s.subspec 'UIKit' do |ss|
    ss.ios.source_files = 'Categories/UIKit/*'
    ss.dependency 'PromiseKit/CorePromise'
    ss.ios.frameworks = 'UIKit'
  end


####################################################### deprecated
  %w{base Promise Pause Until When Join Hang Zalgo}.each do |name|
    s.subspec name do |ss|
      #ss.deprecated = true
      ss.dependency 'PromiseKit/CorePromise'
    end
  end

  s.subspec 'all' do |ss|
    #ss.deprecated = true
    ss.dependency 'PromiseKit/Accounts'
    ss.dependency 'PromiseKit/AVFoundation'
    ss.dependency 'PromiseKit/CloudKit'
    ss.dependency 'PromiseKit/CoreLocation'
    ss.dependency 'PromiseKit/Foundation'
    ss.dependency 'PromiseKit/MapKit'
    ss.dependency 'PromiseKit/Social'
    ss.dependency 'PromiseKit/StoreKit'
    ss.dependency 'PromiseKit/UIKit'
    ss.dependency 'PromiseKit/QuartzCore'
  end

  %w{ACAccountStore AVAudioSession CLGeocoder CKContainer CKDatabase CLLocationManager MKDirections MKMapSnapshotter NSFileManager NSNotificationCenter NSTask NSURLConnection SKRequest SKProductsRequest SLRequest UIActionSheet UIAlertView UIView UIViewController CALayer}.each do |name|
    prefix = name[0..1]
    framework = case prefix
      when 'UI' then 'UIKit'
      when 'CL' then 'CoreLocation'
      when 'MK' then 'MapKit'
      when 'AV' then 'AVFoundation'
      when 'AC' then 'Accounts'
      when 'SL' then 'Social'
      when 'SK' then 'StoreKit'
      when 'CK' then 'CloudKit'
      when 'CA' then 'QuartzCore'
      else 'Foundation'
    end
    s.subspec name do |ss|
      ss.dependency "PromiseKit/#{framework}"
      #ss.deprecated = true
    end
  end

  s.subspec 'Swift' do |ss|
    #ss.deprecated = true
    ss.default_subspecs = 'Foundation', 'UIKit'

    ss.subspec 'Promise' do |sss|
      #sss.deprecated = true
      sss.dependency 'PromiseKit/CorePromise'
    end
    
    ss.subspec 'NSJSONFromData' do |sss|
      #sss.deprecated = true
      sss.dependency 'PromiseKit/CorePromise'
    end      

    %w{CloudKit UIKit CoreLocation MapKit Social StoreKit Foundation NSNotificationCenter Accounts AVFoundation}.each do |name|
      ss.subspec(name) do |sss|
        #sss.deprecated = true
        sss.dependency "PromiseKit/#{name}"
      end
    end

    ss.subspec 'all' do |sss|
      #sss.deprecated = true
      sss.dependency 'PromiseKit/Swift/CloudKit'
      sss.dependency 'PromiseKit/Swift/CoreLocation'
      sss.dependency 'PromiseKit/Swift/Foundation'
      sss.dependency 'PromiseKit/Swift/MapKit'
      sss.dependency 'PromiseKit/Swift/Social'
      sss.dependency 'PromiseKit/Swift/StoreKit'
      sss.dependency 'PromiseKit/Swift/UIKit'
    end
  end  
end
