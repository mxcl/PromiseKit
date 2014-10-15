Pod::Spec.new do |s|
  s.name = "PromiseKit"
  s.version = "1.0"
  s.source = { :git => "https://github.com/mxcl/#{s.name}.git", :tag => s.version }
  s.license = 'MIT'
  s.summary = 'A delightful Promises implementation for iOS and OS X.'
  s.homepage = 'http://promisekit.org'
  s.social_media_url = 'https://twitter.com/mxcl'
  s.authors  = { 'Max Howell' => 'mxcl@me.com' }
  s.documentation_url = 'http://promisekit.org/api/'
  s.default_subspecs = 'NSURLConnection', 'NSNotificationCenter',
                       'UIActionSheet', 'UIAlertView', 'UIViewController', 'UIView',
                       'Pause', 'When', 'Until'
  s.requires_arc = true
  s.ios.deployment_target = '6.0'    # due to https://github.com/CocoaPods/CocoaPods/issues/1001
  s.osx.deployment_target = '10.7'

  def s.mksubspec name, ios: nil, osx: nil
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
      
      yield(ss) if block_given?

      ss = if !ios
        ss.ios.deployment_target = nil
        ss.osx
      elsif !osx
        ss.osx.deployment_target = nil
        ss.ios
      else
        ss
      end

      ss.framework = framework
      ss.source_files = (ss.source_files rescue []) + ["objc/#{name}+PromiseKit.h", "objc/#{name}+PromiseKit.m", "objc/deprecated/PromiseKit+#{framework}.h"]
      ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
    end
  end

  s.subspec 'Promise' do |ss|
    ss.source_files = 'objc/PromiseKit.h', 'objc/PMKPromise.m', 'objc/PromiseKit/Promise.h', 'objc/PromiseKit/fwd.h'
    ss.preserve_paths = 'objc/PromiseKit', 'objc/Private'
    ss.frameworks = 'Foundation'
  end

  %w{Pause Until When}.each do |name|
    s.subspec(name) do |ss|
      ss.source_files = "objc/PMKPromise+#{name}.m", "objc/PromiseKit/Promise+#{name}.h"
      ss.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) PMK_#{name.upcase}=1" }
      ss.preserve_paths = 'objc/PromiseKit'
      ss.dependency 'PromiseKit/When' if name == 'Until'
      ss.dependency 'PromiseKit/Promise'
    end
  end

  s.mksubspec 'ACAccountStore', ios: '6.0', osx: '10.8'
  s.mksubspec 'AVAudioSession', ios: '7.0'
  s.mksubspec 'CLGeocoder', ios: '5.0', osx: '10.8'
  s.mksubspec 'CKContainer', ios: '8.0', osx: '10.10'
  s.mksubspec 'CKDatabase', ios: '8.0', osx: '10.10'
  s.mksubspec 'CLLocationManager', ios: '2.0', osx: '10.6'
  s.mksubspec 'MKDirections', ios: '7.0', osx: '10.9'
  s.mksubspec 'MKMapSnapshotter', ios: '7.0', osx: '10.9'
  s.mksubspec 'NSFileManager', ios: '2.0', osx: '10.5'
  s.mksubspec 'NSNotificationCenter', ios: '4.0', osx: '10.6'
  s.mksubspec 'NSTask', osx: '10.0'
  s.mksubspec 'NSURLConnection', ios: '5.0', osx: '10.7' do |ss|
    ss.dependency "OMGHTTPURLRQ"
  end
  s.mksubspec 'SKRequest', ios: '3.0', osx: '10.7'
  s.mksubspec 'SLRequest', ios: '6.0', osx: '10.8'
  s.mksubspec 'UIActionSheet', ios: '2.0'
  s.mksubspec 'UIAlertView', ios: '2.0'
  s.mksubspec 'UIView', ios: '4.0' do |ss|
    ss.ios.source_files = 'objc/deprecated/PromiseKit+UIAnimation.h'
  end
  s.mksubspec 'UIViewController', ios: '5.0' do |ss|
    ss.ios.weak_frameworks = 'AssetsLibrary'
  end

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

  s.subspec 'all' do |ss|
    ss.dependency 'PromiseKit/When'
    ss.dependency 'PromiseKit/Until'
    ss.dependency 'PromiseKit/Pause'

    ss.dependency 'PromiseKit/Accounts'
    ss.dependency 'PromiseKit/AVFoundation'
    ss.dependency 'PromiseKit/CloudKit'
    ss.dependency 'PromiseKit/CoreLocation'
    ss.dependency 'PromiseKit/Foundation'
    ss.dependency 'PromiseKit/MapKit'
    ss.dependency 'PromiseKit/Social'
    ss.dependency 'PromiseKit/StoreKit'
    ss.dependency 'PromiseKit/UIKit'
  end

#### deprecated

  s.subspec 'SKProductsRequest' do |ss|
    ss.deprecated_in_favor_of = 'PromiseKit/SKRequest'
    ss.dependency 'PromiseKit/SKRequest'
    ss.preserve_paths = 'objc/deprecated'
    ss.source_files = 'objc/deprecated/SKProductsRequest+PromiseKit.h'
  end

  s.subspec 'base' do |ss|   # deprecated
    ss.deprecated_in_favor_of = 'PromiseKit/Promise'
    ss.dependency 'PromiseKit/Promise'
    ss.dependency 'PromiseKit/When'
    ss.dependency 'PromiseKit/Until'
  end

end
