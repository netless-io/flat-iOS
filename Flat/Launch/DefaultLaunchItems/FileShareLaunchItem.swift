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
    var scene: UIWindowScene?

    func shouldHandle(url: URL?, scene: UIScene) -> Bool {
        guard let url, url.isFileURL else {
            return false
        }
        self.scene = scene as? UIWindowScene
        var temp = FileManager.default.temporaryDirectory
        temp.appendPathComponent(url.lastPathComponent)
        let success = url.startAccessingSecurityScopedResource()
        logger.info("get \(url) access \(success)")
        do {
            if FileManager.default.fileExists(atPath: temp.path) {
                try? FileManager.default.removeItem(at: temp)
            }
            try FileManager.default.copyItem(at: url, to: temp)
            self.url = temp
            url.stopAccessingSecurityScopedResource()
            return true
        } catch {
            logger.error("process share file error, \(error)")
            return false
        }
    }

    func shouldHandle(userActivity _: NSUserActivity, scene: UIScene) -> Bool {
        false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user _: User) {
        guard let top = UIApplication.shared.topWith(windowScene: scene) else { return }
        if top is ClassRoomViewController {
            top.toast(localizeStrings("TryLaunchUploadInClassTip"))
            return
        }
        top.showCheckAlert(message: localizeStrings("Got New File Alert"), completionHandler: {
            guard let mainContainer = UIApplication.shared.topWith(windowScene: self.scene)?.mainContainer else { return }
            if let _ = mainContainer.concreteViewController.presentedViewController {
                mainContainer.concreteViewController.dismiss(animated: false, completion: nil)
            }

            func startWith(_ controller: CloudStorageViewController) {
                // TODO: The temp file does not deleted, in tmp dir
                controller.uploadFile(url: self.url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
            }

            // Select to storage
            if let split = mainContainer.concreteViewController as? MainSplitViewController {
                if #available(iOS 14, *) {
                    if let side = split.viewController(for: .primary) as? RegularSideBarViewController {
                        if let index = side.controllers.firstIndex(where: { ($0 as? UINavigationController)?.topViewController is CloudStorageViewController }) {
                            side.selectedIndex = index
                            if let controller = (side.controllers[index] as? UINavigationController)?.topViewController as? CloudStorageViewController {
                                startWith(controller)
                                return
                            }
                        }
                    }
                }

                if let tab = split.viewControllers.first as? MainTabBarController {
                    if let index = tab.viewControllers?.firstIndex(where: { ($0 as? UINavigationController)?.topViewController is CloudStorageViewController }) {
                        tab.selectedIndex = index
                        if let controller = (tab.viewControllers?[index] as? UINavigationController)?.topViewController as? CloudStorageViewController {
                            startWith(controller)
                            return
                        }
                    }
                }

            } else if let tab = mainContainer.concreteViewController as? MainTabBarController {
                if let index = tab.viewControllers?.firstIndex(where: { ($0 as? UINavigationController)?.topViewController is CloudStorageViewController }) {
                    tab.selectedIndex = index
                    if let controller = (tab.viewControllers?[index] as? UINavigationController)?.topViewController as? CloudStorageViewController {
                        startWith(controller)
                        return
                    }
                }
            }
        })
    }
}
