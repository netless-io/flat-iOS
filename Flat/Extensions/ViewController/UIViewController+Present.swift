//
//  UIViewController+Present.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

private var closeBlockKey: Void?
extension UIViewController {
    typealias CloseBlockType = ()->Void
    var closeBlock: CloseBlockType? {
        get {
            objc_getAssociatedObject(self, &closeBlockKey) as? CloseBlockType
        }
        set {
            objc_setAssociatedObject(self, &closeBlockKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    @discardableResult
    func addPresentCloseButton(_ handler: CloseBlockType? = nil) -> UIButton {
        self.closeBlock = handler
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "close-bold"), for: .normal)
        closeButton.tintColor = .text
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.top).offset(28)
            make.width.height.equalTo(44)
        }
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        return closeButton
    }
    
    @objc func onClose() {
        if let closeBlock = closeBlock {
            closeBlock()
        } else {
            dismiss(animated: true)
        }
    }
    
    @discardableResult
    func addPresentTitle(_ title: String) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .strongText
        titleLabel.text = title
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.top).offset(28)
        }
        return titleLabel
    }
}
