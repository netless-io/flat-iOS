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
    typealias CloseBlockType = () -> Void
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
        closeBlock = handler
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "close-bold"), for: .normal)
        closeButton.tintColor = .color(type: .text)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide)
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
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .color(type: .text, .strong)
        titleLabel.textAlignment = .center
        titleLabel.text = title
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide.snp.top).offset(28)
            make.right.left.equalTo(view.safeAreaLayoutGuide).inset(44)
        }

        if !isCompact() {
            let line = UIView()
            line.backgroundColor = .borderColor
            view.addSubview(line)
            line.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().inset(56)
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }

        return titleLabel
    }
}
