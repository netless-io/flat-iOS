//
//  EmptySplitSecondaryViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIViewController {
    static func emptySplitSecondaryViewController() -> EmptySplitSecondaryViewController { .init() }
}

class EmptySplitSecondaryViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteBG
        let imgView = UIImageView(image: UIImage(named: "split_empty"))
        view.addSubview(imgView)
        imgView.snp.makeConstraints({ $0.center.equalToSuperview() })
    }
}
