//
//  MainSplitViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class MainSplitViewController: UISplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        preferredDisplayMode = .oneBesideSecondary
        viewControllers = [BaseNavigationViewController(rootViewController: HomeViewController()), emptyDetailController]
    }
    
    lazy var emptyDetailController = EmptySplitSecondaryViewController()
}
