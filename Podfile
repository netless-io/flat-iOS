platform :ios, '12.0'

target 'Flat' do
  use_frameworks!
  
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'NSObject+Rx'
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'Kingfisher'
  pod 'Hero'
  pod 'SnapKit'
  pod 'EmptyDataSet-Swift'
  pod 'IQKeyboardManagerSwift'
  pod 'AgoraRtm_iOS'
  pod 'AgoraRtcEngine_iOS'
  pod 'WechatOpenSDK'
  pod 'Fastboard', '1.0.0-beta.2'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end

