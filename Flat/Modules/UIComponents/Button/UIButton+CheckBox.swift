//
//  UIButton+CheckBox.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIButton {
    static func checkBoxStyleButton() -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tintColor = .white
        btn.setImage(UIImage(named: "checklist_normal"), for: .normal)
        btn.setImage(UIImage(named: "checklist_normal"), for: .reserved)
        btn.setImage(UIImage(named: "checklist_selected"), for: .highlighted)
        btn.setImage(UIImage(named: "checklist_selected"), for: .selected)
        btn.adjustsImageWhenHighlighted = false
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        return btn
    }
}
