
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
  s.documentation_url = 'http://promisekit.org/api'
  s.default_subspecs = 'CALayer', 'NSURLConnection', 'NSNotificationCenter',
                       'UIActionSheet', 'UIAlertView', 'UIViewController', 'UIView',
                       'Pause', 'When', 'Until'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
  s.osx.deployment_target = '10.7'
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
        [split.call(a), split.call(a)].max.join(".")
      end

      ss.dependency 'PromiseKit/Promise'
      ss.preserve_paths = 'objc/PromiseKit'

      # becuase CocoaPods won't lint if the deployment targets of subspecs
      # are different to the deployment targets of the root spec we have
      # to just pretend everything is the same as the root spec :P
      # https://github.com/CocoaPods/CocoaPods/issues/1987
      if ios
        #ss.ios.deployment_target = max.call(ios, self.deployment_target(:ios))
        ss.ios.deployment_target = deployment_target(:ios)
      end
      if osx
        #ss.osx.deployment_target = max.call(osx, self.deployment_target(:osx))
        ss.osx.deployment_target = deployment_target(:osx)
      end
	  if watchos
	  	ss.watchos.deployment_target = deployment_target(:watchos)
	  end
	  if tvos
	  	ss.tvos.deployment_target = deployment_target(:tvos)
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
	      os.source_files = (ss.source_files rescue []) + ["objc/#{name}+PromiseKit.h", "objc/#{name}+PromiseKit.m"]
	      os.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
		else
		  os.deployment_target = nil
		end
	  end
	  
    end
  end

  s.subspec 'Promise' do |ss|
    ss.source_files = 'objc/PromiseKit.h', 'objc/PMKPromise.m', 'objc/PromiseKit/Promise.h', 'objc/PromiseKit/fwd.h'
    ss.preserve_paths = 'objc/PromiseKit', 'objc/Private'
    ss.frameworks = 'Foundation'
  end

  %w{Pause Until When Join Hang Zalgo}.each do |name|
    s.subspec(name) do |ss|
      ss.source_files = "objc/PMKPromise+#{name}.m", "objc/PromiseKit/Promise+#{name}.h"
      ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
      ss.preserve_paths = 'objc/PromiseKit'
      ss.dependency 'PromiseKit/When' if name == 'Until'
      ss.dependency 'PromiseKit/Until' if name == 'Join'
      ss.dependency 'PromiseKit/Promise'
    end
  end

  s.mksubspec 'ACAccountStore', ios: '6.0', osx: '10.8'
  s.mksubspec 'AVAudioSession', ios: '7.0'#, tvos: '9.0' # `requestRecordPermission:` not available on tvOS
  s.mksubspec 'CLGeocoder', ios: '5.0', osx: '10.8', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'CKContainer', ios: '8.0', osx: '10.10'#, tvos: '9.0' # `discoverAllContactUserInfosWithCompletionHandler:` not available on tvOS
  s.mksubspec 'CKDatabase', ios: '8.0', osx: '10.10', tvos: '9.0'
  s.mksubspec 'CLLocationManager', ios: '2.0', osx: '10.6'
  s.mksubspec 'MKDirections', ios: '7.0', osx: '10.9'
  s.mksubspec 'MKMapSnapshotter', ios: '7.0', osx: '10.9', tvos: '9.0'
  s.mksubspec 'NSFileManager', ios: '2.0', osx: '10.5', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'NSNotificationCenter', ios: '4.0', osx: '10.6', watchos: '2.0', tvos: '9.0'
  s.mksubspec 'NSTask', osx: '10.0'
  s.mksubspec 'NSURLConnection', ios: '5.0', osx: '10.7' do |ss| 
  	# `sendAsynchronousRequest:` not available on tvOS and watchOS
	# Need OMG 3.x for tv/watch support but PK 1.x NSURLConnection+PK files need updated for it - Nathan
	
	# ss.dependency "OMGHTTPURLRQ", "~> 2.1"
  	# Even though watchos and tvos versions are not specified for this subspec, for some
	# reason their dependencies are still being set if we're not explicit here - Nathan
    ss.ios.dependency "OMGHTTPURLRQ", "~> 2.1"
	ss.osx.dependency "OMGHTTPURLRQ", "~> 2.1"
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
  end
  s.subspec 'AVFoundation' do |ss|
    ss.dependency 'PromiseKit/AVAudioSession'
  end
  s.subspec 'CloudKit' do |ss|
    ss.dependency 'PromiseKit/CKContainer'
    ss.dependency 'PromiseKit/CKDatabase'
  end
  s.subspec 'CoreLocation' do |ss|
    ss.dependency 'PromiseKit/CLGeocoder'
    ss.dependency 'PromiseKit/CLLocationManager'
  end
  s.subspec 'Foundation' do |ss|
    ss.dependency 'PromiseKit/NSFileManager'
    ss.dependency 'PromiseKit/NSNotificationCenter'
    ss.dependency 'PromiseKit/NSTask'
    ss.dependency 'PromiseKit/NSURLConnection'
  end
  s.subspec 'MapKit' do |ss|
    ss.dependency 'PromiseKit/MKDirections'
    ss.dependency 'PromiseKit/MKMapSnapshotter'
  end
  s.subspec 'Social' do |ss|
    ss.dependency 'PromiseKit/SLRequest'
  end
  s.subspec 'StoreKit' do |ss|
    ss.dependency 'PromiseKit/SKRequest'
  end
  s.subspec 'UIKit' do |ss|
    ss.dependency 'PromiseKit/UIActionSheet'
    ss.dependency 'PromiseKit/UIAlertView'
    ss.dependency 'PromiseKit/UIView'
    ss.dependency 'PromiseKit/UIViewController'
  end
  s.subspec 'QuartzCore' do |ss|
    ss.dependency 'PromiseKit/CALayer'
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
  end
end
