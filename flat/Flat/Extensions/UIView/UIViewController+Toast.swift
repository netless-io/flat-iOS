//
//  UIViewController+Toast.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/4.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

extension UIViewController {
    func toast(_ text: String,
               timeinterval: TimeInterval = 1.5) {
        let frame = NSString(string: text).boundingRect(with: .init(width: 66, height: 66), attributes: [.font: toastLabel.font!], context: nil)
        let size = frame.insetBy(dx: -20, dy: -10).size
        toastLabel.bounds = .init(origin: .zero, size: size)
        toastLabel.center = view.center
        toastLabel.text = text
        toastLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + timeinterval) {
            self.toastLabel.isHidden = true
        }
    }
    
    fileprivate var toastLabel: UILabel {
        let toastLabelTag = 888
        let toastLabel: UILabel
        if let label = view.viewWithTag(toastLabelTag) as? UILabel {
            toastLabel = label
        } else {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 14)
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.numberOfLines = 0
            label.textAlignment = .center
            label.tag = toastLabelTag
            label.clipsToBounds = true
            label.layer.cornerRadius = 4
            toastLabel = label
            view.addSubview(toastLabel)
        }
        view.bringSubviewToFront(toastLabel)
        return toastLabel
    }
}
