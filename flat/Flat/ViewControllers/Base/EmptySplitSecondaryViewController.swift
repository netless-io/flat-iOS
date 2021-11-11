//
//  EmptySplitSecondaryViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class EmptySplitSecondaryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let imgView = UIImageView(image: UIImage(named: "split_empty"))
        view.addSubview(imgView)
        imgView.snp.makeConstraints({ $0.center.equalToSuperview() })
    }
}
