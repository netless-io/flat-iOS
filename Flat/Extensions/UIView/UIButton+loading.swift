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
            button.isLoading = loading
        }
    }
}

extension UIButton {
    var isLoading: Bool {
        get { false }
        set {
            if !newValue {
                if let normal = savedNormalImage {
                    setImage(normal, for: .normal)
                }
                if let selected = savedSelectedImage {
                    setImage(selected, for: .selected)
                }
                if let normal = savedNormalText {
                    setTitle(normal, for: .normal)
                }
                if let selected = savedSelectedText {
                    setTitle(selected, for: .selected)
                }
                
                activityView.stopAnimating()
                isUserInteractionEnabled = true
                return
            }
            if activityView.superview == nil {
                addSubview(activityView)
                activityView.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(self).multipliedBy(0.6)
                }
            }
            var white: CGFloat = 0
            backgroundColor?.getWhite(&white, alpha: nil)
            activityView.color = white > 0.45 ? .white : .color(type: .text)
            
            savedNormalImage = image(for: .normal)
            savedSelectedImage = image(for: .selected)
            savedNormalText = title(for: .normal)
            savedSelectedText = title(for: .selected)
            setImage(nil, for: .normal)
            setImage(nil, for: .selected)
            setTitle("", for: .normal)
            setTitle("", for: .selected)
            
            activityView.startAnimating()
            isUserInteractionEnabled = false
        }
    }
}

private var savedNormalImageKey: Void?
private var savedSelectedImageKey: Void?
private var savedNormalTextKey: Void?
private var savedSelectedTextKey: Void?
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
    
    fileprivate var savedNormalText: String? {
        get {
            objc_getAssociatedObject(self, &savedNormalTextKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &savedNormalTextKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    fileprivate var savedSelectedText: String? {
        get {
            objc_getAssociatedObject(self, &savedSelectedTextKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &savedSelectedTextKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
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
                activityView.color = .white
            } else {
                activityView = UIActivityIndicatorView(style: .white)
            }
            activityView.tag = activityTag
            activityView.hidesWhenStopped = true
        }
        return activityView
    }
}
