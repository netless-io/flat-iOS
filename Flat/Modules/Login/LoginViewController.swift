//
//  LoginViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxRelay
import RxSwift
import UIKit

class LoginViewController: UIViewController {
    enum LoginType {
        case sms
        case password

        func toggle() -> Self {
            switch self {
            case .password: return .sms
            case .sms: return .password
            }
        }
    }

    let loginType: BehaviorRelay<LoginType> = .init(value: .sms)

    @IBOutlet var splitStackView: UIStackView!
    @IBOutlet var contentStackView: UIStackView!

    // Regular
    @IBOutlet var loginRegularBg: LoginBackgroundView!
    @IBOutlet var regularLogoStackView: UIStackView!
    @IBOutlet var flatLabel: UILabel!

    // Compact
    @IBOutlet var compactBackgroundLogoView: CompactLoginBackgroundView!

    // Common
    @IBOutlet var authInputStackView: UIStackView!
    @IBOutlet var loginTypeToggleButton: UIButton!
    @IBOutlet var forgetPasswordButton: UIButton!
    @IBOutlet var loginButton: FlatGeneralCrossButton!
    @IBOutlet var registerButton: SpringButton!
    @IBOutlet var tipsLabel: UILabel!
    @IBOutlet var thirdPartLoginStackView: UIStackView!

    @IBOutlet var appleLoginButton: UIButton!
    @IBOutlet var googleLoginButton: UIButton!
    @IBOutlet var githubLoginButton: UIButton!
    @IBOutlet var weChatLoginButton: UIButton!

    var webLinkLogin: WebLinkLoginItem?
    var weChatLogin: WeChatLogin?
    var appleLogin: Any?
    var lastSMSLoginPhone: String? {
        get {
            UserDefaults.standard.value(forKey: "lastLoginPhone") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lastLoginPhone")
        }
    }

    var deviceAgreementAgree: Bool {
        get {
            UserDefaults.standard.value(forKey: "deviceAgreementAgree") as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "deviceAgreementAgree")
            if newValue {
                startGoogleAnalytics()
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .compact {
            return .portrait
        } else {
            return .all
        }
    }

    deinit {
        logger.trace("\(self) deinit")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !deviceAgreementAgree {
            showDeviceAgreeAlert()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        hideDisabledLoginTypes()
        loadHistory()
        bind()
        #if DEBUG
            let debugSelector = #selector(debugLogin(sender:))
            if responds(to: debugSelector) {
                let doubleTap = UITapGestureRecognizer(target: self, action: debugSelector)
                doubleTap.numberOfTapsRequired = 2
                view.addGestureRecognizer(doubleTap)
            }
        #endif
    }

    // MARK: - Action -

    @objc
    func onClickRegister(sender: UIButton) {
        let vc = SignUpViewController()
        present(vc, animated: true)
    }
    
    @objc
    func onClickLogin(sender: UIButton) {
        switch loginType.value {
        case .sms: smsLogin()
        case .password: passwordLogin()
        }

        func passwordLogin() {
            func processPasswordLoginResult(_ result: Result<User, Error>) {
                stopActivityIndicator()
                switch result {
                case let .success(user):
                    AuthStore.shared.lastAccountLoginInfo = .init(
                        account: self.passwordAuthView.accountTextfield.accountType.value,
                        regionCode: self.passwordAuthView.accountTextfield.country.code,
                        inputText: self.passwordAuthView.accountTextfield.text ?? "",
                        pwd: self.passwordAuthView.passwordTextfield.passwordText
                    )
                    AuthStore.shared.processLoginSuccessUserInfo(user)
                case let .failure(error):
                    self.toast(error.localizedDescription)
                }
            }
            let request: PasswordLoginRequest
            let account = passwordAuthView.accountTextfield.accountText
            let password = passwordAuthView.passwordTextfield.passwordText
            switch self.passwordAuthView.accountTextfield.accountType.value {
            case .email:
                request = PasswordLoginRequest(account: .email(account), password: password)
            case .phone:
                request = PasswordLoginRequest(account: .phone(account), password: password)
            }
            agreementCheck { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    showActivityIndicator()
                    ApiProvider.shared.request(fromApi: request, completionHandler: processPasswordLoginResult)
                case .failure: return
                }
            }
        }

        func smsLogin() {
            let phone = smsAuthView.fullPhoneText
            let code = smsAuthView.codeText
            agreementCheck { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    let request = PhoneSMSLoginRequest(phone: phone, code: code)
                    let activity = showActivityIndicator()
                    ApiProvider.shared.request(fromApi: request) { [weak self] result in
                        activity.stopAnimating()
                        switch result {
                        case let .success(user):
                            self?.lastSMSLoginPhone = self?.smsAuthView.phoneTextfield.text
                            AuthStore.shared.processLoginSuccessUserInfo(user)
                        case let .failure(error):
                            self?.toast(error.localizedDescription)
                        }
                    }
                case .failure: return
                }
            }
        }
    }

    @IBAction
    func onToggleLoginType(_: Any) {
        loginType.accept(loginType.value.toggle())
    }

    @IBAction
    func onClickForgetPassword(_: Any) {
        let vc = ResetPasswordViewController()
        present(vc, animated: true)
    }

    // MARK: - Private -

    func hideDisabledLoginTypes() {
        let env = Env().disabledLoginTypes
        for type in env {
            switch type {
            case .apple: appleLoginButton.isHidden = true
            case .google: googleLoginButton.isHidden = true
            case .github: githubLoginButton.isHidden = true
            case .wechat: weChatLoginButton.isHidden = true
            case .phone, .email: return // Can't hide yet.
            }
        }
    }
    
    func setupViews() {
        // UI
        registerButton.layer.borderWidth = commonBorderWidth
        registerButton.tintAdjustmentMode = .dimmed
        registerButton.setTraitRelatedBlock { btn in
            let borderColor = UIColor.color(light: .grey3, dark: .grey6).resolvedColor(with: btn.traitCollection)
            let titleColor = UIColor.color(light: .grey6, dark: .grey3).resolvedColor(with: btn.traitCollection)
            btn.layer.borderColor = borderColor.cgColor
            btn.setTitleColor(titleColor, for: .normal)
        }
        [loginTypeToggleButton, forgetPasswordButton].forEach {
            $0?.tintColor = .color(type: .primary)
        }
        [smsAuthView, passwordAuthView].forEach {
            authInputStackView.addArrangedSubview($0)
        }

        splitStackView.arrangedSubviews.forEach {
            $0.backgroundColor = .color(type: .background)
        }
        flatLabel.textColor = .color(type: .text, .strong)

        let i = contentStackView.arrangedSubviews.firstIndex(of: registerButton) ?? 0
        contentStackView.insertArrangedSubview(agreementCheckStackView, at: i + 1)
        agreementCheckStackView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        tipsLabel.textColor = .color(type: .text)
        tipsLabel.adjustsFontSizeToFitWidth = true
        tipsLabel.minimumScaleFactor = 0.7
        syncTraitCollection(traitCollection)

        // Others
        smsAuthView.verificationCodeTextfield.sendSMSAddtionalCheck = { [weak self] sender in
            guard let self else { return .failure("") }
            let agree = self.checkAgreementDidAgree()
            if agree { return .success(()) }
            self.showAgreementCheckAlert(agreeAction: { [weak self, weak sender] in
                guard let self,
                      let sender = sender as? UIButton
                else { return }
                self.smsAuthView.verificationCodeTextfield.onClickSendSMS(sender: sender)
            }, cancelAction: nil)
            return .failure("")
        }
        smsAuthView.verificationCodeTextfield.smsRequestMaker = { [weak self] in
            guard let self else { return .error("self not exist") }
            let phone = self.smsAuthView.fullPhoneText
            return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .login(phone: phone)))
        }
        
        smsAuthView.presentRoot = self

        passwordAuthView.accountTextfield.presentRoot = self
        loginButton.addTarget(self, action: #selector(onClickLogin(sender:)), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(onClickRegister(sender:)), for: .touchUpInside)

        // Hide weChat login when weChat not installed
        weChatLoginButton.isHidden = !WXApi.isWXAppInstalled()
    }

    func agreementCheck(handler: @escaping ((Result<Void, Error>) -> Void)) {
        let agree = checkAgreementDidAgree()
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

    func updateLoginType(_ type: LoginType) {
        switch type {
        case .password:
            smsAuthView.isHidden = true
            passwordAuthView.isHidden = false
            loginButton.setTitle(localizeStrings("Login"), for: .normal)
            loginTypeToggleButton.setTitle(localizeStrings("smsAuth"), for: .normal)
            forgetPasswordButton.isHidden = false
            registerButton.isHidden = false
            passwordAuthView.accountTextfield.becomeFirstResponder()
        case .sms:
            smsAuthView.isHidden = false
            passwordAuthView.isHidden = true
            loginButton.setTitle(localizeStrings("LoginOrRegister"), for: .normal)
            loginTypeToggleButton.setTitle(localizeStrings("passwordAuth"), for: .normal)
            forgetPasswordButton.isHidden = true
            registerButton.isHidden = true
            smsAuthView.phoneTextfield.becomeFirstResponder()
        }
    }

    func loadHistory() {
        smsAuthView.phoneTextfield.text = lastSMSLoginPhone
        
        if let info = AuthStore.shared.lastAccountLoginInfo {
            passwordAuthView.accountTextfield.fillWith(countryCode: info.regionCode, inputText: info.inputText)
            passwordAuthView.passwordTextfield.text = info.pwd
        }
    }

    func showDeviceAgreeAlert() {
        let vc = PrivacyAlertViewController(
            agreeClick: { [unowned self] in
                self.dismiss(animated: false)
                self.deviceAgreementAgree = true
            },
            cancelClick: {
                exit(0)
            },
            alertTitle: localizeStrings("Service and privacy"),
            agreeTitle: localizeStrings("Agree and continue"),
            rejectTitle: localizeStrings("Disagree and exit"),
            attributedString: agreementAttributedString()
        )
        vc.clickEmptyToCancel = false
        present(vc, animated: true)
    }

    func bind() {
        loginType
            .subscribe(with: self) { ws, type in
                UIView.animate(withDuration: 0.3) {
                    ws.updateLoginType(type)
                }
            }
            .disposed(by: rx.disposeBag)

        Observable.combineLatest(
            loginType.asObservable(),
            smsAuthView.loginEnable,
            passwordAuthView.loginEnable
        ) { type, x, y -> Bool in
            switch type {
            case .sms: return x
            case .password: return y
            }
        }
        .asDriver(onErrorJustReturn: true)
        .drive(loginButton.rx.isEnabled)
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
            attributedString: agreementAttributedString1()
        )
        present(vc, animated: true)
    }

    func checkAgreementDidAgree() -> Bool {
        agreementCheckStackView.isSelected
    }

    func syncTraitCollection(_ trait: UITraitCollection) {
        if trait.horizontalSizeClass == .compact || trait.verticalSizeClass == .compact {
            loginRegularBg.isHidden = true
            compactBackgroundLogoView.isHidden = false
            regularLogoStackView.isHidden = true
        } else {
            compactBackgroundLogoView.isHidden = true
            loginRegularBg.isHidden = false
            regularLogoStackView.isHidden = false
        }
    }

    @objc
    @IBAction func onClickAppleLogin(sender: UIButton) {
        guard checkAgreementDidAgree() else {
            showAgreementCheckAlert(agreeAction: { [weak self] in
                self?.onClickAppleLogin(sender: sender)
            }, cancelAction: nil)
            return
        }
        showActivityIndicator()
        appleLogin = AppleLogin()
        (appleLogin as! AppleLogin).startLogin(sender: sender) { [weak self] result in
            self?.stopActivityIndicator()
            switch result {
            case .success:
                return
            case let .failure(error):
                self?.showAlertWith(message: error.localizedDescription.isEmpty ? localizeStrings("Login fail") : error.localizedDescription)
            }
        }
    }

    @IBAction func onClickWeChatButton() {
        guard checkAgreementDidAgree() else {
            showAgreementCheckAlert(agreeAction: { [weak self] in
                self?.onClickWeChatButton()
            }, cancelAction: nil)
            return
        }
        guard let launchCoordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        weChatLogin?.removeLaunchItemFromLaunchCoordinator?()
        weChatLogin = WeChatLogin()
        weChatLogin?.startLogin(withAuthStore: AuthStore.shared,
                                launchCoordinator: launchCoordinator)
        { [weak self] result in
            switch result {
            case let .success(user):
                logger.info("weChat login user: \(user.name) \(user.userUUID)")
                return
            case let .failure(error):
                self?.showAlertWith(message: error.localizedDescription.isEmpty ? localizeStrings("Login fail") : error.localizedDescription)
            }
        }
    }

    @IBAction func onClickWebLinkLoginButton(sender: UIButton) {
        var urlMaker: ((String)->URL)?
        if sender === githubLoginButton {
            urlMaker = Env().githubLoginURLWith(authUUID:)
        } else if sender === googleLoginButton {
            urlMaker = Env().googleLoginURLWith(authUUID:)
        }
        guard let urlMaker else { return }
        guard checkAgreementDidAgree() else {
            showAgreementCheckAlert(agreeAction: { [weak self] in
                self?.onClickWebLinkLoginButton(sender: sender)
            }, cancelAction: nil)
            return
        }
        guard let coordinator = globalLaunchCoordinator else { return }
        showActivityIndicator()
        webLinkLogin = WebLinkLoginItem()
        webLinkLogin?.startLogin(withAuthStore: AuthStore.shared,
                                      launchCoordinator: coordinator,
                                      sender: sender,
                                      urlMaker: urlMaker) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            self.webLinkLogin = nil
            switch result {
            case .success:
                return
            case let .failure(error):
                self.showAlertWith(message: error.localizedDescription)
            }
        }
    }

    // MARK: - Lazy -

    lazy var smsAuthView = SMSAuthView()
    lazy var passwordAuthView = PasswordAuthView()
    
    lazy var agreementCheckStackView = AgreementCheckView(presentRoot: self)
}
