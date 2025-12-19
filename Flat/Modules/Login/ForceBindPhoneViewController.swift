//
//  BindPhoneViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class ForceBindPhoneViewController: UIViewController {
    var isRebinding = false
    
    override init(nibName _: String?, bundle _: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        view.backgroundColor = .color(type: .background)

        let mainView = UIView()
        let stack = UIStackView(arrangedSubviews: [])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        view.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        if !traitCollection.hasCompact {
            let leftView = LoginBackgroundView()
            stack.addArrangedSubview(leftView)
        }
        stack.addArrangedSubview(mainView)

        if traitCollection.hasCompact {
            addPresentTitle(localizeStrings("BindPhone"))
            addPresentCloseButton {
                AuthStore.shared.logout()
            }

            mainView.addSubview(smsAuthView)
            smsAuthView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(66)
            }

            bindButton.setTitle(localizeStrings("Confirm"), for: .normal)
            mainView.addSubview(bindButton)
            bindButton.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.top.equalTo(smsAuthView.snp.bottom).offset(28)
            }

            smsAuthView
                .loginEnable
                .asDriver(onErrorJustReturn: true)
                .drive(bindButton.rx.isEnabled)
                .disposed(by: rx.disposeBag)
        } else {
            mainView.addSubview(smsAuthView)
            smsAuthView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.72)
            }

            bindButton.setTitle(localizeStrings("Confirm"), for: .normal)
            mainView.addSubview(bindButton)
            bindButton.snp.makeConstraints { make in
                make.left.right.equalTo(smsAuthView)
                make.height.equalTo(40)
                make.top.equalTo(smsAuthView.snp.bottom).offset(32)
            }

            smsAuthView
                .loginEnable
                .asDriver(onErrorJustReturn: true)
                .drive(bindButton.rx.isEnabled)
                .disposed(by: rx.disposeBag)

            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
            titleLabel.textColor = .color(type: .text, .strong)
            titleLabel.text = localizeStrings("BindPhone")
            mainView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(smsAuthView.snp.top).offset(-100)
            }

            let bindPhoneDetailLabel = UILabel()
            bindPhoneDetailLabel.text = localizeStrings("Bind Phone Detail")
            bindPhoneDetailLabel.font = .systemFont(ofSize: 14)
            bindPhoneDetailLabel.numberOfLines = 0
            bindPhoneDetailLabel.textAlignment = .center
            bindPhoneDetailLabel.textColor = .color(type: .text)
            mainView.addSubview(bindPhoneDetailLabel)
            bindPhoneDetailLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(14)
            }

            let closeButton = UIButton(type: .custom)
            closeButton.setTitleColor(.color(type: .primary), for: .normal)
            closeButton.setTitle(localizeStrings("Back"), for: .normal)
            closeButton.titleLabel?.font = .systemFont(ofSize: 14)
            mainView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.size.equalTo(bindButton)
                make.top.equalTo(bindButton.snp.bottom).offset(4)
                make.centerX.equalToSuperview()
            }
            closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        }
    }

    @objc
    func onLogin(sender: UIButton) {
        let activity = showActivityIndicator()
        if isRebinding {
            let request = RebindingPhoneRequest(phone: smsAuthView.fullPhoneText, code: smsAuthView.codeText)
            ApiProvider.shared.request(fromApi: request) { [weak self] result in
                activity.stopAnimating()
                switch result {
                case .success(let user):
                    AuthStore.shared.processLoginSuccessUserInfo(user, relogin: true)
                case let .failure(error):
                    self?.toast(error.localizedDescription)
                }
            }
        } else {
            let request = BindingPhoneRequest(phone: smsAuthView.fullPhoneText, code: smsAuthView.codeText)
            ApiProvider.shared.request(fromApi: request) { [weak self] result in
                activity.stopAnimating()
                switch result {
                case .success:
                    AuthStore.shared.processBindPhoneSuccess()
                case let .failure(error):
                    self?.toast(error.localizedDescription)
                }
            }
        }
    }
    
    func showRebindAlert() {
        showCheckAlert(message: localizeStrings("rebindingPhoneTips")) {
            self.smsAuthView.verificationCodeTextfield.smsRequestMaker = { [weak self] captchaVerifyParam in
                guard let smsAuthView = self?.smsAuthView else { return .error("self not exist") }
                let phone = smsAuthView.fullPhoneText
                guard let captchaVerifyParam, captchaVerifyParam.isNotEmptyOrAllSpacing else { return .error("captchaVerifyParam missing") }
                return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .rebind(phone: phone, captchaVerifyParam: captchaVerifyParam)))
            }
            self.smsAuthView.verificationCodeTextfield.onClickSendSMS(sender: self.smsAuthView.verificationCodeTextfield.smsButton)
            self.isRebinding = true
        }
    }

    lazy var smsAuthView: SMSAuthView = {
        let view = SMSAuthView()
        view.verificationCodeTextfield.smsRequestMaker = { [weak view] captchaVerifyParam in
            guard let view else { return .error("self not exist") }
            let phone = view.fullPhoneText
            guard let captchaVerifyParam, captchaVerifyParam.isNotEmptyOrAllSpacing else { return .error("captchaVerifyParam missing") }
            return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .bind(phone: phone, captchaVerifyParam: captchaVerifyParam)))
        }
        view.verificationCodeTextfield.smsErrorHandler = { [weak self] error in
            if case FlatApiError.PhoneRegistered = error {
                self?.showRebindAlert()
            }
        }
        view.presentRoot = self
        return view
    }()
    
    lazy var bindButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.addTarget(self, action: #selector(self.onLogin(sender:)), for: .touchUpInside)
        return btn
    }()
}
