//
//  AccountCodeAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/10.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class AccountCodeAuthView: UIView {
    var authEnable: Observable<Bool> {
        Observable.combineLatest(
            accountTextfield.accountEnable,
            verifyCodeTextfield.rx.text.orEmpty)
        {
            $0 && !$1.isEmpty
        }
    }
    
    init(staticAccountType: AccountTextfield.AccountType? = nil) {
        accountTextfield = .init(staticAccountType: staticAccountType)
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        accountTextfield = .init()
        super.init(coder: coder)
        setupViews()
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 375, height: UIView.noIntrinsicMetric)
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

        let g0 = UIView()
        stackView.addArrangedSubview(g0)
        g0.snp.makeConstraints { make in
            make.height.equalTo(margin)
        }
        stackView.addArrangedSubview(verifyCodeTextfield)

        accountTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        verifyCodeTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
    }
    
    lazy var verifyCodeTextfield = VerifyCodeTextfield()
    var accountTextfield: AccountTextfield
}
