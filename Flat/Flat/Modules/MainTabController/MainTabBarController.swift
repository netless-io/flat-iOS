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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tabBar.backgroundImage = UIImage.imageWith(color: .blackBG)
    }
    
    func setup() {
        tabBar.backgroundImage = UIImage.imageWith(color: .blackBG)
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .blackBG
        tabBar.barTintColor = .blackBG
        tabBar.tintColor = .blackBG
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
        controller.tabBarItem.image = image.tintColor(.subText)
        controller.tabBarItem.selectedImage = image.tintColor(.white)
        controller.tabBarItem.title = title
        controller.tabBarItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12),
                                                      .foregroundColor: UIColor.init(hexString: "#7A7B7C")], for: .normal)
        controller.tabBarItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12),
                                                      .foregroundColor: UIColor.white], for: .selected)
        let navi = BaseNavigationViewController(rootViewController: controller)
        return navi
    }
}
