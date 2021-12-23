//
//  CustomPreviewViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import QuickLook

class CustomPreviewViewController: QLPreviewController {
    var clickBackHandler: (()->Void)?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let backItem = UIBarButtonItem.init(title: NSLocalizedString("Close", comment: ""), style: .plain, target: self, action: #selector(self.onBack))
        self.navigationItem.setLeftBarButton(backItem, animated: false)
    }
    
    @objc func onBack() {
        mainSplitViewController?.cleanSecondary()
        clickBackHandler?()
    }
}

