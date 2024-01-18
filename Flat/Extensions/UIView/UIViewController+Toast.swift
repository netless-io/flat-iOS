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
               preventTouching: Bool = false,
               offset: CGPoint? = nil,
               hidePreviouds: Bool = true)
    {
        guard !text.isEmpty else { return }
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            if hidePreviouds {
                MBProgressHUD.hide(for: window, animated: false)
            }
            let hud = MBProgressHUD.showAdded(to: window, animated: true)
            hud.bezelView.style = .solidColor
            hud.bezelView.color = UIColor.black.withAlphaComponent(0.45)
            hud.backgroundView.style = .solidColor
            hud.backgroundView.color = UIColor.black.withAlphaComponent(0.05)
            if let offset {
                hud.offset = offset
            }
            hud.mode = .text
            hud.label.textColor = .white
            hud.label.numberOfLines = 5
            hud.label.text = text
            hud.hide(animated: true, afterDelay: timeInterval)
            hud.isUserInteractionEnabled = preventTouching
        }
    }

    func toast(
        _ customView: UIView,
        timeInterval: TimeInterval = 1.5,
        preventTouching: Bool = false
    ) {
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            MBProgressHUD.hide(for: window, animated: false)
            let hud = MBProgressHUD.showAdded(to: window, animated: true)
            hud.bezelView.style = .solidColor
            hud.bezelView.color = UIColor.black.withAlphaComponent(0.45)
            hud.mode = .customView
            hud.customView = customView
            hud.hide(animated: true, afterDelay: timeInterval)
            hud.isUserInteractionEnabled = preventTouching
        }
    }
}

