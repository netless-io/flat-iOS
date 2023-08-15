//
//  SignUpInputView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class SignUpInputView: UIView {
    var signUpEnable: Observable<Bool> {
        Observable.combineLatest(
            accountTextfield.accountEnable,
            passwordTextfield.rx.text.orEmpty
        ) {
            $0 && !$1.isEmpty
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        binding()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        binding()
    }

    // MARK: - Private -

    private func setupViews() {
        backgroundColor = .color(type: .background)

        let margin: CGFloat = 16
        let textfieldHeight: CGFloat = 44
        let stackView = UIStackView(arrangedSubviews: [accountTextfield])
        stackView.axis = .vertical
        stackView.distribution = .fill
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        accountTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }

        [verificationCodeTextfield, passwordTextfield].forEach { tf in
            let g0 = UIView()
            stackView.addArrangedSubview(g0)
            g0.snp.makeConstraints { make in
                make.height.equalTo(margin)
            }
            stackView.addArrangedSubview(tf)
            tf.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        }
    }
    
    private func binding() {
        verificationCodeTextfield.sendSmsEnable = accountTextfield.accountEnable
    }

    lazy var passwordTextfield = PasswordTextfield()
    lazy var accountTextfield = AccountTextfield()
    lazy var verificationCodeTextfield = VerifyCodeTextfield()
}
