//
//  UIView+ActivityIndicator.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/14.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import RxSwift

fileprivate let activityTag = 888
extension Reactive where Base: UIButton {
    var isLoading: Binder<Bool> {
        Binder(self.base) { button, loading in
            if !loading {
                if let normal = button.savedNormalImage {
                    button.setImage(normal, for: .normal)
                }
                if let selected = button.savedSelectedImage {
                    button.setImage(selected, for: .selected)
                }
                
                button.activityView.stopAnimating()
                button.isUserInteractionEnabled = true
                return
            }
            if button.activityView.superview == nil {
                button.addSubview(button.activityView)
                button.activityView.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(button).multipliedBy(0.6)
                }
            }
            button.savedNormalImage = button.image(for: .normal)
            button.savedSelectedImage = button.image(for: .selected)
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .selected)
            
            button.activityView.startAnimating()
            button.isUserInteractionEnabled = false
        }
    }
}

private var savedNormalImageKey: Void?
private var savedSelectedImageKey: Void?
extension UIButton {
    fileprivate var savedNormalImage: UIImage? {
        get {
            objc_getAssociatedObject(self, &savedNormalImageKey) as? UIImage
        }
        set {
            objc_setAssociatedObject(self, &savedNormalImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var savedSelectedImage: UIImage? {
        get {
            objc_getAssociatedObject(self, &savedSelectedImageKey) as? UIImage
        }
        set {
            objc_setAssociatedObject(self, &savedSelectedImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIView {
    fileprivate var activityView: UIActivityIndicatorView {
        let activityView: UIActivityIndicatorView
        if let tagView = viewWithTag(activityTag) as? UIActivityIndicatorView {
            activityView = tagView
        } else {
            if #available(iOS 13.0, *) {
                activityView = UIActivityIndicatorView(style: .medium)
                activityView.tintColor = .white
            } else {
                activityView = UIActivityIndicatorView(style: .white)
            }
            activityView.tag = activityTag
            activityView.hidesWhenStopped = true
        }
        return activityView
    }
}
