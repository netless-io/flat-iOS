platform :ios, '12.0'
target 'Flat' do
  use_frameworks!
  
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'NSObject+Rx'
  
  pod 'AcknowList'
  pod 'CropViewController'
  pod 'Siren'
  pod 'IQKeyboardManagerSwift'
  pod 'Zip'
  
  pod 'AgoraRtm_iOS'
  pod 'AgoraRtcEngine_iOS'
  pod 'Fastboard', '2.0.0-alpha.2'
  pod 'Fastboard/fpa', '2.0.0-alpha.2'
  pod 'Whiteboard', '2.17.0-alpha.6'
  pod 'Whiteboard/SyncPlayer', '0.3.2'
  pod 'SyncPlayer', '0.3.2'
  
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'Kingfisher'
  pod 'Hero'
  pod 'SnapKit'
  pod 'DZNEmptyDataSet'
  
  pod 'Logging'
  pod 'SwiftyBeaver'
  pod 'AliyunLogProducer/Core'
  pod 'AliyunLogProducer/Bricks'

  pod 'WechatOpenSDK'
  pod 'FirebaseCrashlytics'
  pod 'Firebase/AnalyticsWithoutAdIdSupport'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      if config.name.include?("Debug")
        config.build_settings["ONLY_ACTIVE_ARCH"] = "YES"
      end
    end
  end
end

