platform :ios, '12.0'
target 'Flat' do
  use_frameworks!
  
  pod 'AcknowList'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'NSObject+Rx'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'Kingfisher'
  pod 'Hero'
  pod 'SnapKit'
  pod 'DZNEmptyDataSet'
  pod 'IQKeyboardManagerSwift'
  pod 'AgoraRtm_iOS'
  pod 'AgoraRtcEngine_iOS'
  pod 'WechatOpenSDK'
  pod 'Fastboard'
  pod 'Fastboard/fpa'
  pod 'Whiteboard'
  pod 'Siren'
  pod 'CropViewController'
  pod 'Logging'
  pod 'SwiftyBeaver'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      if config.name.include?("Debug")
        config.build_settings["ONLY_ACTIVE_ARCH"] = "YES"
      end
    end
  end
end

