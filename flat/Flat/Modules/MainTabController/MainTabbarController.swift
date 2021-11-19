//
//  MainTabbarController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit

class MainTabbarController: UITabBarController {
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    func setup() {
        tabBar.backgroundImage = UIImage.imageWith(color: .init(hexString: "#1A1E21"))
        tabBar.tintColor = .white
        let home = makeSubController(fromViewController: HomeViewController(), image: UIImage(named: "tab_room")!)
        addChild(home)
        let cloudStorage = makeSubController(fromViewController: CloudStorageViewController(), image: UIImage(named: "tab_cloud_storage")!)
        addChild(cloudStorage)
    }
    
    func makeSubController(
        fromViewController controller: UIViewController,
        image: UIImage
    ) -> UIViewController {
        controller.tabBarItem.image = image
        let navi = BaseNavigationViewController(rootViewController: controller)
        navi.navigationBar.tintColor = .subText
        return navi
    }
}
