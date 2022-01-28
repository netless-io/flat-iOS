//
//  MainTabBarController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.hasCompact ? .portrait : .all
    }
    
    override var shouldAutorotate: Bool { true }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    override func show(_ vc: UIViewController, sender: Any?) {
        if let navi = selectedViewController as? UINavigationController {
            navi.show(vc, sender: sender)
        }
    }
    
    func setup() {
        tabBar.tintColor = .brandColor
        tabBar.isTranslucent = true
        let home = makeSubController(fromViewController: HomeViewController(),
                                     image: UIImage(named: "tab_room")!,
                                     title: NSLocalizedString("Home", comment: ""))
        addChild(home)
        let cloudStorage = makeSubController(fromViewController: CloudStorageViewController(),
                                             image: UIImage(named: "tab_cloud_storage")!,
                                             title: NSLocalizedString("Cloud Storage", comment: ""))
        addChild(cloudStorage)
    }
    
    func makeSubController(
        fromViewController controller: UIViewController,
        image: UIImage,
        title: String
    ) -> UIViewController {
        controller.tabBarItem.image = image
        controller.tabBarItem.title = title
        let navi = BaseNavigationViewController(rootViewController: controller)
        return navi
    }
}
