//
//  UIViewController+Toast.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/4.
//  Copyright © 2021 agora.io. All rights reserved.
//

import MBProgressHUD
import UIKit

func configProgressHUDAppearance() {
    MBProgressHUD.appearance().margin = 10
    MBProgressHUD.appearance().animationType = .zoom
}

extension UIViewController {
    func toast(_ text: String,
               timeInterval: TimeInterval = 1.5,
               preventTouching: Bool = false)
    {
        guard !text.isEmpty else { return }
        DispatchQueue.main.async { [weak view] in
            guard let view else { return }
            MBProgressHUD.hide(for: view, animated: false)
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.bezelView.style = .solidColor
            hud.bezelView.color = UIColor.black.withAlphaComponent(0.45)
            hud.backgroundView.style = .solidColor
            hud.backgroundView.color = UIColor.black.withAlphaComponent(0.05)
            hud.mode = .text
            hud.label.textColor = .white
            hud.label.numberOfLines = 5
            hud.label.text = text
            hud.hide(animated: true, afterDelay: timeInterval)
            hud.isUserInteractionEnabled = preventTouching
        }
    }
}
