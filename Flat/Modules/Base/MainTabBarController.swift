//
//  MainTabBarController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
        } else {
            tabBar.barTintColor = .color(type: .background)
        }
    }
    
    func setup() {
        tabBar.tintColor = .blue6
        tabBar.isTranslucent = true
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .color(type: .background)
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        } else {
            tabBar.barTintColor = .color(type: .background)
        }
        
        let home = makeSubController(fromViewController: HomeViewController(),
                                     image: UIImage(named: "side_home")!,
                                     selectedImage: UIImage(named: "side_home_filled")!,
                                     title: localizeStrings("Home"))
        addChild(home)
        let cloudStorage = makeSubController(fromViewController: CloudStorageViewController(),
                                             image: UIImage(named: "side_cloud")!,
                                             selectedImage: UIImage(named: "side_cloud_filled")!,
                                             title: localizeStrings("Cloud Storage"))
        addChild(cloudStorage)
        
        delegate = self
    }
    
    func makeSubController(
        fromViewController controller: UIViewController,
        image: UIImage,
        selectedImage: UIImage,
        title: String
    ) -> UIViewController {
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = selectedImage
        controller.tabBarItem.title = title
        let navi = BaseNavigationViewController(rootViewController: controller)
        return navi
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if #available(iOS 13.0, *) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
