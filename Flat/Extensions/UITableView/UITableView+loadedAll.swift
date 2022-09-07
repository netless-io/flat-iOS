//
//  UITableView+loadedAll.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/7.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

extension UITableView {
    func showLoadedAll(_ flag: Bool) {
        if !flag { tableFooterView = nil }
        let view = UIView(frame: .init(x: 0, y: 0, width: 0, height: 44))
        view.backgroundColor = .color(type: .background)
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text, .weak)
        label.text = localizeStrings("DidLoadAll")
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        tableFooterView = view
    }
}
