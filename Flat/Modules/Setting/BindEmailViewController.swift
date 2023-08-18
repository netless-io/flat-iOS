//
//  BindEmailViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/17.
//  Copyright © 2023 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class BindEmailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        binding()
    }

    func setupViews() {
        title = localizeStrings("BindEmail")
        view.backgroundColor = .color(type: .background)
        view.addSubview(mainContentView)
        mainContentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().inset(16).priority(.medium)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(14)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.snp.bottom).inset(16).priority(.medium)
        }
        
        authView.accountTextfield.presentRoot = self
        authView.verifyCodeTextfield.smsRequestMaker = { [unowned self] in
            ApiProvider.shared.request(fromApi: SMSRequest(scenario: .bindEmail(self.authView.accountTextfield.accountText)))
        }
    }

    func binding() {
        authView.authEnable
            .asDriver(onErrorJustReturn: false)
            .drive(updateButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }

    @objc
    func onConfirm() {
        let account = authView.accountTextfield.accountText
        let code = authView.verifyCodeTextfield.text ?? ""
        
        let request = BindingEmailRequest(email: account, code: code)
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: request) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            switch result {
            case .success:
                LoginViewController.lastAccountLoginText = account
                self.toast(localizeStrings("Success"), timeInterval: 2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self else { return }
                    self.navigationController?.popViewController(animated: true)
                }
            case let .failure(error):
                self.toast(error.localizedDescription)
            }
        }
    }

    lazy var mainContentView: UIStackView = {
        let spacer = UIView()
        let view = UIStackView(arrangedSubviews: [authView, spacer, updateButton])
        view.axis = .vertical
        view.spacing = 16
        updateButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return view
    }()

    lazy var updateButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.setTitle(localizeStrings("Confirm"), for: .normal)
        btn.addTarget(self, action: #selector(onConfirm))
        return btn
    }()

    lazy var authView = AccountCodeAuthView(staticAccountType: .email)
}
