//
//  LoginViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import AuthenticationServices
import SafariServices

class LoginViewController: UIViewController {
    @IBOutlet weak var smsAuthView: SMSAuthView!
    @IBOutlet weak var loginButton: FlatGeneralCrossButton!
    var wechatLogin: WechatLogin?
    var githubLogin: GithubLogin?
    @IBOutlet weak var flatLabel: UILabel!
    var appleLogin: Any?
    var lastLoginPhone: String? {
        get {
            UserDefaults.standard.value(forKey: "lastLoginPhone") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "lastLoginPhone")
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
        print(self, "deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadHistory()
        bind()
        #if DEBUG
        let sel = Selector(("debugLogin"))
        if responds(to: sel) {
            let doubleTap = UITapGestureRecognizer(target: self, action: sel)
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
        }
        #endif
    }
    
    // MARK: - Valid
    var phoneValid: Bool {
        guard let text = smsAuthView.phoneTextfield.text,
              (try? text.matchExpressionPattern("1[3456789]\\d{9}$")) != nil
        else { return false }
        return true
    }
    
    var codeValid: Bool { smsAuthView.codeText.count > 0 }
    
    // MARK: - Action
    @objc
    func onClickSendSMS() {
        guard checkAgreementDidAgree() else {
            toast(NSLocalizedString("Please agree to the Terms of Service first", comment: ""))
            return
        }
        guard phoneValid else {
            toast(NSLocalizedString("InvalidPhone", comment: ""))
            return
        }
        let activity = showActivityIndicator()
        let request = SMSRequest(phone: smsAuthView.fullPhoneText)
        ApiProvider.shared.request(fromApi: request) { [weak self] result in
            activity.stopAnimating()
            switch result {
            case .success(_):
                self?.toast(NSLocalizedString("CodeSend", comment: ""))
                self?.smsAuthView.startTimer()
            case .failure(let error):
                self?.toast(NSLocalizedString(error.localizedDescription, comment: ""))
            }
        }
    }
    
    @objc
    func onClickLogin() {
        guard checkAgreementDidAgree() else {
            toast(NSLocalizedString("Please agree to the Terms of Service first", comment: ""))
            return
        }
        guard phoneValid else {
            toast(NSLocalizedString("InvalidPhone", comment: ""))
            return
        }
        guard codeValid else {
            toast(NSLocalizedString("InvalidCode", comment: ""))
            return
        }
        let request = PhoneLoginRequest(phone: smsAuthView.fullPhoneText, code: smsAuthView.codeText)
        let activity = showActivityIndicator()
        ApiProvider.shared.request(fromApi: request) { [weak self] result in
            activity.stopAnimating()
            switch result {
            case .success(let user):
                self?.lastLoginPhone = self?.smsAuthView.phoneTextfield.text
                AuthStore.shared.processLoginSuccessUserInfo(user)
            case .failure(let error):
                self?.toast(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private
    func setupViews() {
        stackView.arrangedSubviews.forEach {
            $0.backgroundColor = .whiteBG
        }
        flatLabel.textColor = .text
        
        // Hide wechat login when wechat not installed
        wechatLoginButton.isHidden = !WXApi.isWXAppInstalled()
        syncTraitCollection(traitCollection)
        if #available(iOS 13.0, *) {
            setupAppleLogin()
        }
        view.addSubview(agreementCheckStackView)
        agreementCheckStackView.snp.makeConstraints { make in
            make.centerX.equalTo(verticalLoginTypesStackView)
            make.top.equalTo(loginButton.snp.bottom).offset(16)
        }
    }
    
    func loadHistory() {
        smsAuthView.phoneTextfield.text = lastLoginPhone
    }
    
    func bind() {
        smsAuthView.smsButton.addTarget(self, action: #selector(onClickSendSMS), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(onClickLogin), for: .touchUpInside)
    }
    
    func checkAgreementDidAgree() -> Bool {
        agreementCheckButton.isSelected
    }
    
    func syncTraitCollection(_ trait: UITraitCollection) {
        if trait.horizontalSizeClass == .compact || trait.verticalSizeClass == .compact {
            loginBg.isHidden = true
        } else {
            loginBg.isHidden = false
        }
    }
    
    @available(iOS 13.0, *)
    func setupAppleLogin() {
        let container = UIView()
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        container.addSubview(button)
        horizontalLoginTypesStackView.addArrangedSubview(container)
        container.snp.makeConstraints { make in
            make.width.equalTo(82)
        }
        button.addTarget(self, action: #selector(onClickAppleLogin), for: .touchUpInside)
        button.cornerRadius = 29
        button.removeConstraints(button.constraints)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(58)
            make.center.equalToSuperview()
        }
    }
    
    @available(iOS 13.0, *)
    @objc func onClickAppleLogin() {
        guard checkAgreementDidAgree() else {
            toast(NSLocalizedString("Please agree to the Terms of Service first", comment: ""))
            return
        }
        guard let launchCoordinator = globalLaunchCoordinator else { return }
        showActivityIndicator()
        appleLogin = AppleLogin()
        (appleLogin as! AppleLogin).startLogin(launchCoordinator: launchCoordinator) { [weak self] result in
            self?.stopActivityIndicator()
            switch result {
            case .success:
                return
            case .failure(let error):
                self?.showAlertWith(message: error.localizedDescription.isEmpty ? "Login fail" : error.localizedDescription)
            }
        }
    }
    
    @IBAction func onClickWechatButton(_ sender: Any) {
        guard checkAgreementDidAgree() else {
            toast(NSLocalizedString("Please agree to the Terms of Service first", comment: ""))
            return
        }
        guard let launchCoordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        self.wechatLogin?.removeLaunchItemFromLaunchCoordinator?()
        self.wechatLogin = WechatLogin()
        self.wechatLogin?.startLogin(withAuthStore: AuthStore.shared,
                                 launchCoordinator: launchCoordinator) { [weak self] result in
            switch result {
            case .success(let user):
                #if DEBUG
                print("wechat login user: \(user)")
                #endif
                return
            case .failure(let error):
                self?.showAlertWith(message: error.localizedDescription.isEmpty ? "Login fail" : error.localizedDescription)
            }
        }
    }
    
    @IBAction func onClickGithubButton(_ sender: Any) {
        guard checkAgreementDidAgree() else {
            toast(NSLocalizedString("Please agree to the Terms of Service first", comment: ""))
            return
        }
        guard let coordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        self.githubLogin?.removeLaunchItemFromLaunchCoordinator?()
        self.githubLogin = GithubLogin()
        self.githubLogin?.startLogin(withAuthStore: AuthStore.shared,
                                     launchCoordinator: coordinator, completionHandler: { [weak self] result in
            switch result {
            case .success(_):
                return
            case .failure(let error):
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
    
    @IBOutlet weak var verticalLoginTypesStackView: UIStackView!
    @IBOutlet weak var horizontalLoginTypesStackView: UIStackView!
    @IBOutlet weak var loginBg: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var githubLoginButton: UIButton!
    @IBOutlet weak var wechatLoginButton: UIButton!
    
    // MARK: Lazy
    lazy var agreementCheckButton: UIButton = {
        let btn = UIButton.checkBoxStyleButton()
        btn.setTitleColor(.text, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitle("  " + NSLocalizedString("Have read and agree", comment: "") + " ", for: .normal)
        btn.addTarget(self, action: #selector(onClickAgreement), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 0)
        return btn
    }()
    
    lazy var agreementCheckStackView: UIStackView = {
        let privacyButton = UIButton(type: .custom)
        privacyButton.tintColor = .brandColor
        privacyButton.setTitleColor(.brandColor, for: .normal)
        privacyButton.titleLabel?.font = .systemFont(ofSize: 12)
        privacyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        privacyButton.addTarget(self, action: #selector(onClickPrivacy), for: .touchUpInside)
        
        let serviceAgreementButton = UIButton(type: .custom)
        serviceAgreementButton.tintColor = .brandColor
        serviceAgreementButton.titleLabel?.font = .systemFont(ofSize: 12)
        serviceAgreementButton.setTitle(NSLocalizedString("Service Agreement", comment: ""), for: .normal)
        serviceAgreementButton.setTitleColor(.brandColor, for: .normal)
        serviceAgreementButton.addTarget(self, action: #selector(onClickServiceAgreement), for: .touchUpInside)
        
        let label1 = UILabel()
        label1.textColor = .text
        label1.font = .systemFont(ofSize: 12)
        label1.text = " " + NSLocalizedString("and", comment: "") + " "
        let view = UIStackView(arrangedSubviews: [agreementCheckButton, privacyButton, label1, serviceAgreementButton])
        view.axis = .horizontal
        view.distribution = .fill
        return view
    }()
}
