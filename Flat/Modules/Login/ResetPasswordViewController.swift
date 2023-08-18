//
//  ResetPasswordViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController {
    enum Step {
        case verify
        case reset
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .fullScreen
        }
        preferredContentSize = .init(width: 480, height: 480)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var presentingTitleLabel: UILabel?

    var step: Step = .verify {
        didSet {
            UIView.animate(withDuration: 0.3) {
                self.update(self.step)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        update(step)
        binding()
    }

    func setupViews() {
        view.backgroundColor = .color(type: .background)
        let isInNavigation = navigationController != nil
        if isInNavigation {
            navigationItem.title = localizeStrings("ResetPassword")
        } else {
            presentingTitleLabel = addPresentTitle(localizeStrings("ResetPassword"))
            addPresentCloseButton { [weak self] in
                self?.presentingViewController?.dismiss(animated: true)
            }
        }
        view.addSubview(mainContentView)
        mainContentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().inset(16).priority(.medium)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(isInNavigation ? 0 : 44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.snp.bottom).inset(16).priority(.medium)
        }

        accountCodeAuthView.verifyCodeTextfield.smsRequestMaker = { [weak self] in
            guard let self else { return .error("self not exist") }

            let account = self.accountCodeAuthView.accountTextfield.accountText
            let request: SMSRequest
            let isCN = LocaleManager.language == .Chinese
            switch self.accountCodeAuthView.accountTextfield.accountType.value {
            case .email:
                request = .init(scenario: .resetEmail(account, language: isCN ? .zh : .en))
            case .phone:
                request = .init(scenario: .resetPhone(account))
            }
            return ApiProvider.shared.request(fromApi: request)
        }
    }

    func update(_ step: Step) {
        let isInNavigation = navigationController != nil
        let title: String
        switch step {
        case .reset:
            resetTipsLabel.isHidden = false
            resetButton.isHidden = false
            resetView.isHidden = false
            nextButton.isHidden = true
            accountCodeAuthView.isHidden = true
            title = localizeStrings("ResetPassword")
        case .verify:
            resetTipsLabel.isHidden = true
            resetButton.isHidden = true
            resetView.isHidden = true
            nextButton.isHidden = false
            accountCodeAuthView.isHidden = false
            title = localizeStrings("SettingNewPassword")
        }
        if isInNavigation {
            navigationItem.title = title
        } else {
            presentingTitleLabel?.text = title
        }
    }

    func binding() {
        accountCodeAuthView.authEnable
            .asDriver(onErrorJustReturn: false)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)

        resetView.passwordEnable
            .asDriver(onErrorJustReturn: false)
            .drive(resetButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }

    // MARK: - Action -

    @objc
    func onNext() {
        step = .reset
    }

    @objc
    func onReset() {
        let request: ResetPasswordRequest
        let account = accountCodeAuthView.accountTextfield.accountText
        let code = accountCodeAuthView.verifyCodeTextfield.text ?? ""
        let password = resetView.p1.text ?? ""
        let loginRequest: PasswordLoginRequest
        switch accountCodeAuthView.accountTextfield.accountType.value {
        case .email:
            request = ResetPasswordRequest(type: .email(account), code: code, password: password)
            loginRequest = .init(account: .email(account), password: password)
        case .phone:
            request = ResetPasswordRequest(type: .phone(account), code: code, password: password)
            loginRequest = .init(account: .phone(account), password: password)
        }
        let login = ApiProvider.shared.request(fromApi: loginRequest)
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: request)
            .flatMap { _ in login }
            .subscribe(with: self, onNext: { ws, user in
                ws.stopActivityIndicator()
                AuthStore.shared.processLoginSuccessUserInfo(user)
                LoginViewController.lastAccountLoginText = account
                LoginViewController.lastAccountLoginPwd = password
            }, onError: { ws, error in
                ws.stopActivityIndicator()
                ws.toast(error.localizedDescription)
                ws.step = .verify
            })
            .disposed(by: rx.disposeBag)
    }

    lazy var mainContentView: UIStackView = {
        let spacer = UIView()
        let view = UIStackView(arrangedSubviews: [accountCodeAuthView, resetView, spacer, nextButton, resetButton, resetTipsLabel])
        view.axis = .vertical
        nextButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        resetButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        resetTipsLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        return view
    }()

    lazy var accountCodeAuthView = AccountCodeAuthView()
    lazy var resetView = PasswordRepeatView()

    lazy var nextButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.setTitle(localizeStrings("NextStep"), for: .normal)
        btn.addTarget(self, action: #selector(onNext))
        return btn
    }()

    lazy var resetButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.setTitle(localizeStrings("ResetCheckButtonTitle"), for: .normal)
        btn.addTarget(self, action: #selector(onReset))
        return btn
    }()

    lazy var resetTipsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text, .weak)
        label.textAlignment = .center
        label.text = localizeStrings("ResetPasswordTips")
        return label
    }()
}
