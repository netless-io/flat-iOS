//
//  DeviceAutorizationHelper.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/1.
//  Copyright © 2022 agora.io. All rights reserved.
//

import AVFoundation

class DeviceAutorizationHelper {
    enum DeviceType {
        case video
        case mic
    }

    weak var rootController: UIViewController?
    init(rootController: UIViewController) {
        self.rootController = rootController
    }

    static func isPermissionAutorized(type: DeviceType) -> Bool {
        switch type {
        case .video:
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        case .mic:
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }

    static func grantPermissionFrom(controller: UIViewController, type: DeviceType, completionHandler: @escaping ((Bool) -> Void)) {
        switch type {
        case .video:
            func failCamera() {
                completionHandler(false)
                DispatchQueue.main.async {
                    controller.showCheckAlert(checkTitle: localizeStrings("GoSetting"), message: localizeStrings("CameraDenyTip")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            let videoAuth = AVCaptureDevice.authorizationStatus(for: .video)
            switch videoAuth {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        completionHandler(true)
                    } else {
                        failCamera()
                    }
                }
                return
            case .restricted:
                failCamera()
            case .denied:
                failCamera()
            case .authorized:
                completionHandler(true)
            @unknown default:
                failCamera()
            }
        case .mic:
            func failMic() {
                completionHandler(false)
                DispatchQueue.main.async {
                    controller.showCheckAlert(checkTitle: localizeStrings("GoSetting"), message: localizeStrings("MicDenyTip")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            let micAuth = AVCaptureDevice.authorizationStatus(for: .audio)
            switch micAuth {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if granted {
                        completionHandler(true)
                    } else {
                        failMic()
                    }
                }
                return
            case .restricted:
                failMic()
            case .denied:
                failMic()
            case .authorized:
                completionHandler(true)
            @unknown default:
                failMic()
            }
        }
    }
}

extension DeviceAutorizationHelper: CameraMicToggleViewDelegate {
    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, cameraOn _: Bool) -> Bool {
        if DeviceAutorizationHelper.isPermissionAutorized(type: .video) { return true }
        guard let root = rootController else { return true }
        DeviceAutorizationHelper.grantPermissionFrom(controller: root, type: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    view.onButtonClick(view.cameraButton)
                }
            }
        }
        return false
    }

    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, micOn _: Bool) -> Bool {
        if DeviceAutorizationHelper.isPermissionAutorized(type: .mic) { return true }
        guard let root = rootController else { return true }
        DeviceAutorizationHelper.grantPermissionFrom(controller: root, type: .mic) { granted in
            if granted {
                DispatchQueue.main.async {
                    view.onButtonClick(view.microphoneButton)
                }
            }
        }
        return false
    }
}
