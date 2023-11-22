//
//  UIViewController+SafaArea.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

extension UIViewController {
    func fillTopSafeAreaWith(color: UIColor) {
        let fillView = UIView()
        fillView.backgroundColor = color
        view.addSubview(fillView)
        fillView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
    
    func fillBottomSafeAreaWith(color: UIColor) {
        let fillView = UIView()
        fillView.backgroundColor = color
        view.addSubview(fillView)
        fillView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.bottom.equalTo(view)
        }
    }
}
