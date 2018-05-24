
Pod::Spec.new do |s|
  s.name = "PromiseKit"

  `xcodebuild -project PromiseKit.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort if $1.nil?
  s.version = $1

  s.source = { :git => "https://github.com/mxcl/#{s.name}.git", :tag => s.version }
  s.license = 'MIT'
  s.summary = 'A delightful Promises implementation for iOS and OS X.'
  s.homepage = 'http://promisekit.org'
  s.description = 'UIActionSheet UIAlertView CLLocationManager MFMailComposeViewController ACAccountStore StoreKit SKRequest SKProductRequest blocks'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://promisekit.org/docs/'
  s.default_subspecs = 'CALayer', 'NSURLConnection', 'NSNotificationCenter',
                       'UIActionSheet', 'UIAlertView', 'UIViewController', 'UIView',
                       'Pause', 'When', 'Until'
  s.requires_arc = true
  
  # CocoaPods requires the root spec to have deployment info even though it should get it from the subspecs
  s.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  def s.mksubspec name, ios: nil, osx: nil, watchos: nil, tvos: nil
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

    subspec(name) do |ss|

      # this method because CocoaPods insists 
      max = Proc.new do |a, b|
        split = Proc.new{ |f| f.split('.').map{|s| s.to_i } }
        [split.call(a), split.call(b)].max.join(".")
      end

      ss.dependency 'PromiseKit/Promise'
      ss.preserve_paths = 'Sources/PromiseKit'

      if ios
        ss.ios.deployment_target = max.call(ios, '6.0')  # we have to be at least the same as the deployment target of our Promise subspec
      end
      if osx
        ss.osx.deployment_target = max.call(osx, '10.7')  # we have to be at least the same as the deployment target of our Promise subspec
      end
  	  if watchos
  	  	ss.watchos.deployment_target = max.call(watchos, '2.0')  # we have to be at least the same as the deployment target of our Promise subspec
  	  end
  	  if tvos
  	  	ss.tvos.deployment_target = max.call(tvos, '9.0')  # we have to be at least the same as the deployment target of our Promise subspec
  	  end
		      
      yield(ss) if block_given?
	  
  	  operating_systems = method(__method__).parameters.select{ |arg| arg[1] != :name }.map { |arg| arg[1].to_s }
	  
  	  operating_systems.each do |os_name|
  	  	os, version = case os_name
    		  when 'ios' then [ss.ios, ios]
    		  when 'osx' then [ss.osx, osx]
    		  when 'watchos' then [ss.watchos, watchos]
    		  when 'tvos' then [ss.tvos, tvos]
    		end
		
      	if version
          os.framework = framework
          os.source_files = (ss.source_files rescue []) + ["Sources/#{name}+PromiseKit.h", "Sources/#{name}+PromiseKit.m"]
          os.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
    		else
    		  os.deployment_target = nil
    		end
  	  end
    end
  end

  s.subspec 'Promise' do |ss|
    ss.source_files = 'Sources/PromiseKit.h', 'Sources/PMKPromise.m', 'Sources/PromiseKit/Promise.h', 'Sources/PromiseKit/fwd.h'
    ss.preserve_paths = 'Sources/PromiseKit', 'Sources/Private'
    ss.frameworks = 'Foundation'

    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.7'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  %w{Pause Until When Join Hang Zalgo}.each do |name|
    s.subspec(name) do |ss|
      ss.source_files = "Sources/PMKPromise+#{name}.m", "Sources/PromiseKit/Promise+#{name}.h"
      ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
      ss.preserve_paths = 'Sources/PromiseKit'
      ss.dependency 'PromiseKit/When' if name == 'Until'
      ss.dependency 'PromiseKit/Until' if name == 'Join'
      ss.dependency 'PromiseKit/Promise'
      
      ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
      ss.watchos.deployment_target = '2.0'
      ss.tvos.deployment_target = '9.0'
      
      if name == 'When' || name == 'Until' || name == 'Join'
        ss.osx.deployment_target = '10.8'
      else
        ss.osx.deployment_target = '10.7'
      end
    end
  end

  s.mksubspec 'ACAccountStore', ios: '6.0', osx: '10.8'
  s.mksubspec 'AVAudioSession', ios: '7.0'
  s.mksubspec 'CLGeocoder', ios: '5.0', osx: '10.8', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'CKContainer', ios: '8.0', osx: '10.10'
  s.mksubspec 'CKDatabase', ios: '8.0', osx: '10.10', tvos: '9.0'
  s.mksubspec 'CLLocationManager', ios: '2.0', osx: '10.6'
  s.mksubspec 'MKDirections', ios: '7.0', osx: '10.9'
  s.mksubspec 'MKMapSnapshotter', ios: '7.0', osx: '10.9', tvos: '9.0'
  s.mksubspec 'NSFileManager', ios: '2.0', osx: '10.5', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'NSNotificationCenter', ios: '4.0', osx: '10.6', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'NSTask', osx: '10.0'
  s.mksubspec 'NSURLConnection', ios: '5.0', osx: '10.9' do |ss| 
    ss.dependency "OMGHTTPURLRQ", "~> 3.2"
  end
  s.mksubspec 'SKRequest', ios: '3.0', osx: '10.7', tvos: '9.0'
  s.mksubspec 'SLRequest', ios: '6.0', osx: '10.8'
  s.mksubspec 'UIActionSheet', ios: '2.0'
  s.mksubspec 'UIAlertView', ios: '2.0'
  s.mksubspec 'UIView', ios: '4.0'

  s.mksubspec 'UIViewController', ios: '5.0' do |ss|
    ss.ios.weak_frameworks = 'AssetsLibrary'
  end
  s.mksubspec 'CALayer', ios: '2.0', osx: '10.5', tvos: '9.0'

  s.subspec 'Accounts' do |ss|
    ss.dependency 'PromiseKit/ACAccountStore'
    ss.ios.deployment_target = '6.0'
    ss.osx.deployment_target = '10.8'
    ss.watchos.deployment_target = nil
    ss.tvos.deployment_target = nil
  end
  s.subspec 'AVFoundation' do |ss|
    ss.dependency 'PromiseKit/AVAudioSession'
    ss.ios.deployment_target = '7.0'
    ss.watchos.deployment_target = nil
    ss.tvos.deployment_target = nil
    ss.osx.deployment_target = nil
  end
  s.subspec 'CloudKit' do |ss|
    ss.dependency 'PromiseKit/CKContainer'
    ss.dependency 'PromiseKit/CKDatabase'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    ss.tvos.deployment_target = '9.0'
    ss.watchos.deployment_target = nil    
  end
  s.subspec 'CoreLocation' do |ss|
    ss.dependency 'PromiseKit/CLGeocoder'
    ss.dependency 'PromiseKit/CLLocationManager'
    ss.ios.deployment_target = '5.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.8'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end
  s.subspec 'Foundation' do |ss|
    ss.dependency 'PromiseKit/NSFileManager'
    ss.dependency 'PromiseKit/NSNotificationCenter'
    ss.dependency 'PromiseKit/NSTask'
    ss.dependency 'PromiseKit/NSURLConnection'
    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.9'   # due to OMGHTTPURLRQ
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end
  s.subspec 'MapKit' do |ss|
    ss.dependency 'PromiseKit/MKDirections'
    ss.dependency 'PromiseKit/MKMapSnapshotter'
    ss.ios.deployment_target = '7.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.9'
    ss.tvos.deployment_target = '9.0'
    ss.watchos.deployment_target = nil    
  end
  s.subspec 'Social' do |ss|
    ss.dependency 'PromiseKit/SLRequest'
    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.8'
    ss.watchos.deployment_target = nil
    ss.tvos.deployment_target = nil
  end
  s.subspec 'StoreKit' do |ss|
    ss.dependency 'PromiseKit/SKRequest'
    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.7'
    ss.watchos.deployment_target = nil
    ss.tvos.deployment_target = '9.0'
  end
  s.subspec 'UIKit' do |ss|
    ss.dependency 'PromiseKit/UIActionSheet'
    ss.dependency 'PromiseKit/UIAlertView'
    ss.dependency 'PromiseKit/UIView'
    ss.dependency 'PromiseKit/UIViewController'
    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = nil
    ss.watchos.deployment_target = nil
    ss.tvos.deployment_target = '9.0'
  end
  s.subspec 'QuartzCore' do |ss|
    ss.dependency 'PromiseKit/CALayer'
    ss.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.7'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'all' do |ss|
    ss.dependency 'PromiseKit/When'
    ss.dependency 'PromiseKit/Until'
    ss.dependency 'PromiseKit/Pause'
    ss.dependency 'PromiseKit/Join'
    ss.dependency 'PromiseKit/Hang'

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
    
    ss.ios.deployment_target = '8.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
    ss.osx.deployment_target = '10.10'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end
end
