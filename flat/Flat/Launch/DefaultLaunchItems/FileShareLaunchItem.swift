//
//  FileShareLaunchItem.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class FileShareLaunchItem: LaunchItem {
    var url: URL!
    
    func shouldHandle(url: URL?) -> Bool {
        guard let url = url, url.isFileURL else {
            return false
        }
        var temp = FileManager.default.temporaryDirectory
        temp.appendPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: temp.path) {
                try? FileManager.default.removeItem(at: temp)
            }
            try FileManager.default.copyItem(at: url, to: temp)
            self.url = temp
            return true
        }
        catch {
            print("process share file error \(error)")
            return false
        }
    }
    
    func shouldHandle(userActivity: NSUserActivity) -> Bool {
        false
    }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator) {
        return
    }
    
    func afterLoginSuccessImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator, user: User) {
        UIApplication.shared.topViewController?.showCheckAlert(message: NSLocalizedString("Got New File Alert", comment: ""), completionHandler: {
            guard let mainContainer = UIApplication.shared.topViewController?.mainContainer else { return }
            if let _ = mainContainer.concreteViewController.presentedViewController {
                mainContainer.concreteViewController.dismiss(animated: false, completion: nil)
            }
            let vc = UploadHomeViewController()
            mainContainer.push(vc)
            // TODO: The temp file does not deleted, in tmp dir
            vc.uploadFile(url: self.url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        })
    }
}
