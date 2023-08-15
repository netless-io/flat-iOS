//
//  PasswordTextfield.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class PasswordTextfield: BottomLineTextfield {
    var passwordText: String { text ?? "" }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func setupViews() {
        super.setupViews()
        placeholder = localizeStrings("PassCodePlaceholder")
        font = .systemFont(ofSize: 16)
        textColor = .color(type: .text)
        isSecureTextEntry = true

        leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "password_icon"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .color(type: .text)
        leftContainer.addSubview(leftIcon)
        leftContainer.frame = leftIcon.bounds
        leftView = leftContainer

        rightViewMode = .always
        let secretModeContainer = UIView()
        secretModeContainer.frame = .init(origin: .zero, size: .init(width: 44, height: 44))
        secretModeContainer.addSubview(self.secretModeButton)
        secretModeButton.frame = secretModeContainer.bounds
        rightView = secretModeContainer
        
        DispatchQueue.main.async {
            self.syncSecretMode()
        }
    }
    
    
    private func syncSecretMode() {
        secretModeButton.setImage(UIImage(named: isSecureTextEntry ? "secure_keyboard" : "no_secure_keyboard"), for: .normal)
    }
    
    @objc func onClickSecret() {
        isSecureTextEntry.toggle()
        syncSecretMode()
    }
    
    lazy var secretModeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "secure_keyboard"), for: .normal)
        btn.addTarget(self, action: #selector(onClickSecret), for: .touchUpInside)
        btn.tintColor = .color(type: .text)
        return btn
    }()
}
