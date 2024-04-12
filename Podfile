platform :ios, '13.0'
target 'Flat' do
  use_frameworks!

  pod 'LookinServer', :configurations => ['Flat_Debug']
  
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'NSObject+Rx'
  pod 'RxDataSources'
  
  pod 'AcknowList'
  pod 'CropViewController'
  pod 'Siren'
  pod 'IQKeyboardManagerSwift'
  pod 'Zip'
  pod 'lottie-ios'
  pod 'PhoneNumberKit'
  pod 'ScreenCorners'
  
  pod 'AgoraRtm_iOS', '1.5.1'
  pod 'AgoraRtcEngine_iOS', '4.3.0', :subspecs => ['RtcBasic']
  pod 'Fastboard', '2.0.0-alpha.19'
  pod 'Whiteboard', '2.17.0-alpha.30'
  pod 'Whiteboard/SyncPlayer', '2.17.0-alpha.30'
  pod 'SyncPlayer', '0.3.3'
  pod 'ViewDragger', '1.1.0'
  
  pod 'MBProgressHUD', '~> 1.2.0'
  pod 'Kingfisher'
  pod 'Hero'
  pod 'SnapKit'
  pod 'DZNEmptyDataSet'
  
  pod 'Logging'
  pod 'SwiftyBeaver'
  pod 'AliyunLogProducer/Core'
  pod 'AliyunLogProducer/Bricks'
  
  pod 'FirebaseCrashlytics'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/AnalyticsWithoutAdIdSupport'
  
  ignore_whiteboard_rebuild = ENV["ignore_whiteboard_rebuild"] == "true"
  
  post_install do |installer|
    # Fix for XCode 14.3
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
    
    if !ignore_whiteboard_rebuild
      # Rebuild whiteboard bridge with injected code.
      system('sh rebuild_whiteboard_bridge.sh $(pwd)') || exit(1)
      
      # Remove the copy resource
      installer.pods_project.targets.each do |target|
        if target.name == "Whiteboard"
          puts "===================> Find Whiteboard Target"
          build_phase = target.build_phases.find { |bp| bp.display_name == 'Resources' }
          build_phase.clear()
          puts "===================> Clear copy original Whiteboard Resources"
        end
        
        # Remove the original whitebaord resource target
        if target.name == 'Whiteboard-Whiteboard'
          target.remove_from_project
        end
      end
    end

    
    # Remove the copy resource
    installer.pods_project.targets.each do |target|
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end
  end
end

