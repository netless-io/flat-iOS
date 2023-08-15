//
//  PasswordRepeatView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import RxSwift

class PasswordRepeatView: UIView {
    var passwordEnable: Observable<Bool> {
        Observable.combineLatest(
            p1.rx.text.orEmpty,
            p2.rx.text.orEmpty) {
                $0.isValidPassword() && $1 == $0
            }
    }
    
    override init(frame _: CGRect) {
        super.init(frame: .zero)
        setupViews()
        binding()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        binding()
    }

    func binding() {
        
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 375, height: UIView.noIntrinsicMetric)
    }
    
    private func setupViews() {
        backgroundColor = .color(type: .background)

        let textfieldHeight: CGFloat = 44
        let stackView = UIStackView(arrangedSubviews: [p1, p2])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 16
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        [p1, p2].forEach { v in
            v.snp.makeConstraints { make in
                make.height.equalTo(textfieldHeight)
            }
        }
        
        p1.placeholder = localizeStrings("ResetPasswordPlaceholder")
        p2.placeholder = localizeStrings("ResetPasswordPlaceholderAgain")
    }
    
    lazy var p1 = PasswordTextfield()
    lazy var p2 = PasswordTextfield()
}
