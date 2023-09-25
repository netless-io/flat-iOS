//
//  UIWindowScene+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2023/9/25.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

private var blurViewKey: Void?
extension UIWindow {
    var blurView: UIView? {
        get {
            objc_getAssociatedObject(self, &blurViewKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &blurViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIWindowScene {
    func blur(_ enable: Bool) {
        windows.forEach { window in
            if !enable {
                window.blurView?.isHidden = true
            } else {
                let blurView: UIView
                if let i = window.blurView {
                    blurView = i
                } else {
                    let effect = UIBlurEffect(style: .systemUltraThinMaterial)
                    let effectView = UIVisualEffectView(effect: effect)
                    window.addSubview(effectView)
                    
                    let imageView = UIImageView(
                        image:
                            UIImage(systemName: "lock.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))?
                            .withTintColor(.color(type: .primary), renderingMode: .alwaysOriginal)
                    )
                    effectView.contentView.addSubview(imageView)
                    effectView.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                    imageView.snp.makeConstraints { make in
                        make.bottom.equalToSuperview().inset(14)
                        make.centerX.equalToSuperview()
                    }
                    blurView = effectView
                }
                window.blurView = blurView
                blurView.isHidden = false
                window.bringSubviewToFront(blurView)
            }
        }
    }
}
