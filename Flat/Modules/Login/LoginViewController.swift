//
//  LoginViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AuthenticationServices
import RxRelay
import RxSwift
import SafariServices
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
    @IBOutlet var loginRegularBg: UIView!
    @IBOutlet var regularLogoStackView: UIStackView!
    @IBOutlet var flatLabel: UILabel!

    // Compact
    @IBOutlet var compactBgView: UIImageView!
    @IBOutlet var compactGradientView: UIView!

    // Common
    @IBOutlet var authInputStackView: UIStackView!
    @IBOutlet var loginTypeToggleButton: UIButton!
    @IBOutlet var forgetPasswordButton: UIButton!
    @IBOutlet var loginButton: FlatGeneralCrossButton!
    @IBOutlet var registerButton: SpringButton!
    @IBOutlet var tipsLabel: UILabel!
    @IBOutlet var thirdPartLoginStackView: UIStackView!

    @IBOutlet var githubLoginButton: UIButton!
    @IBOutlet var weChatLoginButton: UIButton!

    var weChatLogin: WeChatLogin?
    var githubLogin: GithubLogin?
    var appleLogin: Any?
    var lastSMSLoginPhone: String? {
        get {
            UserDefaults.standard.value(forKey: "lastLoginPhone") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lastLoginPhone")
        }
    }
    
    var lastAccountLoginText: String? {
        get {
            UserDefaults.standard.value(forKey: "lastAccountLoginText") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lastAccountLoginText")
        }
    }
    
    var lastAccountLoginPwd: String? {
        get {
            UserDefaults.standard.value(forKey: "lastAccountLoginPwd") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lastAccountLoginPwd")
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isDark = traitCollection.userInterfaceStyle == .dark
        compactGradientLayer.isHidden = isDark // Show nothing on dark mode.

        if isDark {
            regularGradientLayer.colors = [
                UIColor(hexString: "#1756C3").cgColor,
                UIColor(hexString: "#00225E").cgColor,
            ]
        } else {
            regularGradientLayer.colors = [
                UIColor(hexString: "#69A0FF").cgColor,
                UIColor.white.cgColor,
            ]
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
    func onClickLogin(sender: UIButton) {
        switch loginType.value {
        case .sms: smsLogin()
        case .password: passwordLogin()
        }

        func passwordLogin() {
            func processPasswordLoginResult(_ result: Result<User, ApiError>) {
                stopActivityIndicator()
                switch result {
                case let .success(user):
                    self.lastAccountLoginText = self.passwordAuthView.accountText
                    self.lastAccountLoginPwd = self.passwordAuthView.passwordText
                    AuthStore.shared.processLoginSuccessUserInfo(user)
                case let .failure(error):
                    self.toast(error.localizedDescription)
                }
            }
            agreementCheck { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    showActivityIndicator()
                    switch self.passwordAuthView.accountType.value {
                    case .email:
                        let request = EmailLoginRequest(email: passwordAuthView.accountText, password: passwordAuthView.passwordText)
                        ApiProvider.shared.request(fromApi: request, completionHandler: processPasswordLoginResult)
                    case .phone:
                        let request = PhoneLoginRequest(phone: passwordAuthView.accountText, password: passwordAuthView.passwordText)
                        ApiProvider.shared.request(fromApi: request, completionHandler: processPasswordLoginResult)
                    }
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
        // TODO:
    }

    // MARK: - Private -

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
        loginRegularBg.layer.insertSublayer(regularGradientLayer, at: 0)
        loginRegularBg.setDidLayoutHandle { [weak regularGradientLayer] bounds in
            regularGradientLayer?.frame = bounds
        }
        compactGradientView.backgroundColor = .clear
        compactGradientView.layer.insertSublayer(compactGradientLayer, at: 0)
        compactGradientView.setDidLayoutHandle { [weak compactGradientLayer] bounds in
            compactGradientLayer?.frame = bounds
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
        setupAppleLogin()

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
        smsAuthView.sendSMSAddtionalCheck = { [weak self] sender in
            guard let self else { return .failure("") }
            let agree = self.checkAgreementDidAgree()
            if agree { return .success(()) }
            self.showAgreementCheckAlert(agreeAction: { [weak self, weak sender] in
                guard let self,
                      let sender = sender as? UIButton
                else { return }
                self.smsAuthView.onClickSendSMS(sender: sender)
            }, cancelAction: nil)
            return .failure("")
        }
        smsAuthView.smsRequestMaker = { phone in
            ApiProvider.shared.request(fromApi: SMSRequest(scenario: .login, phone: phone))
        }
        smsAuthView.presentRoot = self

        passwordAuthView.presentRoot = self
        loginButton.addTarget(self, action: #selector(onClickLogin(sender:)), for: .touchUpInside)

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
        passwordAuthView.accountTextfield.text = lastAccountLoginText
        passwordAuthView.passwordTextfield.text = lastAccountLoginPwd
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
                self.agreementCheckButton.isSelected = true
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
        agreementCheckButton.isSelected
    }

    func syncTraitCollection(_ trait: UITraitCollection) {
        if trait.horizontalSizeClass == .compact || trait.verticalSizeClass == .compact {
            loginRegularBg.isHidden = true
            compactGradientView.isHidden = false
            regularLogoStackView.isHidden = true
        } else {
            compactGradientView.isHidden = true
            loginRegularBg.isHidden = false
            regularLogoStackView.isHidden = false
        }
    }

    func setupAppleLogin() {
        let container = UIView()
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        container.addSubview(button)
        thirdPartLoginStackView.addArrangedSubview(container)
        button.addTarget(self, action: #selector(onClickAppleLogin(sender:)), for: .touchUpInside)

        button.cornerRadius = 29
        button.removeConstraints(button.constraints)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(58)
            make.center.equalToSuperview()
        }
    }

    @objc func onClickAppleLogin(sender: UIButton) {
        guard checkAgreementDidAgree() else {
            showAgreementCheckAlert { [weak self] in
                self?.onClickAppleLogin(sender: sender)
            }
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
            showAgreementCheckAlert { [weak self] in
                self?.onClickWeChatButton()
            }
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

    @IBAction func onClickGithubButton(sender: UIButton) {
        guard checkAgreementDidAgree() else {
            showAgreementCheckAlert { [weak self] in
                self?.onClickGithubButton(sender: sender)
            }
            return
        }
        guard let coordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        githubLogin?.removeLaunchItemFromLaunchCoordinator?()
        githubLogin = GithubLogin()
        githubLogin?.startLogin(withAuthStore: AuthStore.shared,
                                launchCoordinator: coordinator,
                                sender: sender,
                                completionHandler: { [weak self] result in
                                    switch result {
                                    case .success:
                                        return
                                    case let .failure(error):
                                        self?.showAlertWith(message: error.localizedDescription)
                                    }
                                })
    }

    @objc func onClickAgreement(sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }

    @objc func onClickPrivacy() {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/privacy.html")!)
        present(controller, animated: true, completion: nil)
    }

    @objc func onClickServiceAgreement() {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/service.html")!)
        present(controller, animated: true, completion: nil)
    }

    // MARK: - Lazy -

    lazy var smsAuthView = SMSAuthView()
    lazy var passwordAuthView = PasswordAuthView()

    lazy var regularGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()

    lazy var compactGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hexString: "#69A0FF").cgColor,
            UIColor.white.cgColor,
        ]
        return layer
    }()

    lazy var agreementCheckButton: UIButton = {
        let btn = UIButton.checkBoxStyleButton()
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.setTitle("  " + localizeStrings("Have read and agree") + " ", for: .normal)
        btn.addTarget(self, action: #selector(onClickAgreement), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 0)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.titleLabel?.minimumScaleFactor = 0.1
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.numberOfLines = 1
        btn.titleLabel?.lineBreakMode = .byClipping
        btn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return btn
    }()

    lazy var agreementCheckStackView: UIStackView = {
        let privacyButton = UIButton(type: .custom)
        privacyButton.tintColor = .color(type: .primary)
        privacyButton.setTitleColor(.color(type: .primary), for: .normal)
        privacyButton.titleLabel?.font = .systemFont(ofSize: 12)
        privacyButton.setTitle(localizeStrings("Privacy Policy"), for: .normal)
        privacyButton.addTarget(self, action: #selector(onClickPrivacy), for: .touchUpInside)

        let serviceAgreementButton = UIButton(type: .custom)
        serviceAgreementButton.tintColor = .color(type: .primary)
        serviceAgreementButton.titleLabel?.font = .systemFont(ofSize: 12)
        serviceAgreementButton.setTitle(localizeStrings("Service Agreement"), for: .normal)
        serviceAgreementButton.setTitleColor(.color(type: .primary), for: .normal)
        serviceAgreementButton.addTarget(self, action: #selector(onClickServiceAgreement), for: .touchUpInside)

        let label1 = UILabel()
        label1.textColor = .color(type: .text)
        label1.font = .systemFont(ofSize: 12)
        label1.text = " " + localizeStrings("and") + " "
        label1.setContentCompressionResistancePriority(.required, for: .horizontal) // Don't compress it.

        let space1 = UIView()
        let space2 = UIView()
        space1.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        space2.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        let view = UIStackView(arrangedSubviews: [space1, agreementCheckButton, privacyButton, label1, serviceAgreementButton, space2])
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        space2.snp.makeConstraints { make in
            make.width.equalTo(space1)
        }
        return view
    }()
}
