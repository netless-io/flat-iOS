//
//  SignUpViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .fullScreen
        }
        preferredContentSize = .init(width: 480, height: 480)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        binding()
    }
    
    func setupViews() {
        view.backgroundColor = .color(type: .background)
        let isInNavigation = navigationController != nil
        if isInNavigation {
            navigationItem.title = localizeStrings("RegisterTitle")
        } else {
            addPresentTitle(localizeStrings("RegisterTitle"))
            addPresentCloseButton { [weak self] in
                self?.presentingViewController?.dismiss(animated: true)
            }
        }
        let spacer = UIView()
        let mainContent = UIStackView(arrangedSubviews: [signUpInputView, spacer, agreementCheckStackView, signUpButton])
        mainContent.axis = .vertical
        view.addSubview(mainContent)
        mainContent.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().inset(16).priority(.medium)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(isInNavigation ? 0 : 44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.snp.bottom).inset(16).priority(.medium)
        }
        agreementCheckStackView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        signUpButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        signUpInputView.verificationCodeTextfield.sendSMSAddtionalCheck = { [weak self] sender in
            guard let self else { return .failure("") }
            let agree = self.agreementCheckStackView.isSelected
            if agree { return .success(()) }
            self.showAgreementCheckAlert(agreeAction: { [weak self, weak sender] in
                guard let self,
                      let sender = sender as? UIButton
                else { return }
                self.signUpInputView.verificationCodeTextfield.onClickSendSMS(sender: sender)
            }, cancelAction: nil)
            return .failure("")
        }

        signUpInputView.accountTextfield.accountType
            .subscribe(with: signUpInputView.verificationCodeTextfield) { tf, type in
                tf.requireCaptchaVerifyParam = (type == .phone)
            }
            .disposed(by: rx.disposeBag)

        signUpInputView.verificationCodeTextfield.smsRequestMaker = { [weak self] captchaVerifyParam in
            guard let self else { return .error("self not exist") }
            let account = self.signUpInputView.accountTextfield.accountText
            let isCN = LocaleManager.language == .Chinese
            switch self.signUpInputView.accountTextfield.accountType.value {
            case .email:
                return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .emailRegister(email: account, language: isCN ? .zh : .en)))
            case .phone:
                guard let captchaVerifyParam, captchaVerifyParam.isNotEmptyOrAllSpacing else { return .error("captchaVerifyParam missing") }
                return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .phoneRegister(phone: account, captchaVerifyParam: captchaVerifyParam)))
            }
        }
        signUpInputView.accountTextfield.presentRoot = self
        
        signUpButton.setTitle(localizeStrings("NextStep"), for: .normal)
        signUpButton.addTarget(self, action: #selector(onClickNext))
    }
    
    func binding() {
        signUpInputView.signUpEnable
            .asDriver(onErrorJustReturn: false)
            .drive(signUpButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }
    
    func showAgreementCheckAlert(agreeAction: (() -> Void)? = nil, cancelAction: (() -> Void)? = nil) {
        let vc = PrivacyAlertViewController(
            agreeClick: { [unowned self] in
                self.dismiss(animated: false)
                self.agreementCheckStackView.isSelected = true
                agreeAction?()
            },
            cancelClick: { [unowned self] in
                self.dismiss(animated: false)
                cancelAction?()
            },
            alertTitle: localizeStrings("Service and privacy"),
            agreeTitle: localizeStrings("Have read and agree"),
            rejectTitle: localizeStrings("Reject"),
            attributedString: Env().useCnSpecialAgreement ? agreementAttributedStringCN_Special() : agreementAttributedString1()
        )
        present(vc, animated: true)
    }
    
    // MARK: - Action -
    @objc
    func onClickNext() {
        let signUpRequest: SignUpRequest
        let loginRequest: PasswordLoginRequest
        let account = signUpInputView.accountTextfield.accountText
        let code = signUpInputView.verificationCodeTextfield.text ?? ""
        let password = signUpInputView.passwordTextfield.passwordText
        
        if !password.isValidPassword() {
            toast(localizeStrings("PasswordValidTips"))
            return
        }
        switch signUpInputView.accountTextfield.accountType.value {
        case .email:
            loginRequest = .init(account: .email(account), password: password)
            signUpRequest = .init(type: .email(account), code: code, password: password)
        case .phone:
            loginRequest = .init(account: .phone(account), password: password)
            signUpRequest = .init(type: .phone(account), code: code, password: password)
        }
        
        let login = ApiProvider.shared.request(fromApi: loginRequest)

        self.checkArgeementWithUI { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                showActivityIndicator()
                ApiProvider.shared.request(fromApi: signUpRequest)
                    .flatMap { _ in login }
                    .subscribe(with: self, onNext: { ws, user in
                        ws.stopActivityIndicator()
                        AuthStore.shared.unsetDefaultProfileUserUUID = user.userUUID
                        AuthStore.shared.processLoginSuccessUserInfo(user)
                        AuthStore.shared.lastAccountLoginInfo = .init(
                            account: ws.signUpInputView.accountTextfield.accountType.value,
                            regionCode: ws.signUpInputView.accountTextfield.country.code,
                            inputText: ws.signUpInputView.accountTextfield.text ?? "",
                            pwd: password
                        )
                    }, onError: { ws, error in
                        ws.stopActivityIndicator()
                        ws.toast(error.localizedDescription)
                    })
                    .disposed(by: rx.disposeBag)
            case .failure:
                return
            }
        }
    }
    
    func checkArgeementWithUI(handler: @escaping ((Result<Void, Error>) -> Void)) {
        let agree = agreementCheckStackView.isSelected
        if agree {
            handler(.success(()))
            return
        }
        showAgreementCheckAlert {
            handler(.success(()))
        } cancelAction: {
            handler(.failure("user reject"))
        }
    }
    
    lazy var signUpInputView = SignUpInputView()
    lazy var agreementCheckStackView = {
        let view = AgreementCheckView(presentRoot: self)
        view.specialEventForCNUserCheckAgreement = {
            self.showAgreementCheckAlert()
        }
        return view
    }()
    lazy var signUpButton = FlatGeneralCrossButton()
}
