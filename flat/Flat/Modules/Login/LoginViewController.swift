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
    var wechatLogin: WechatLogin?
    var githubLogin: GithubLogin?
    var appleLogin: Any?
    
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
        #if DEBUG
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(debugLogin))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        #endif
    }
    
    // MARK: - Private
    func setupViews() {
        // Hide wechat login when wechat not installed
        wechatLoginButton.isHidden = !WXApi.isWXAppInstalled()
        syncTraitCollection(traitCollection)
        if #available(iOS 13.0, *) {
            setupAppleLogin()
        }
        view.addSubview(agreementCheckStackView)
        agreementCheckStackView.snp.makeConstraints { make in
            make.centerX.equalTo(verticalLoginTypesStackView)
            make.top.equalTo(verticalLoginTypesStackView.snp.bottom).offset(34)
        }
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
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
        container.addSubview(button)
        horizontalLoginTypesStackView.addArrangedSubview(container)
        container.snp.makeConstraints { make in
            make.width.equalTo(58)
        }
        button.addTarget(self, action: #selector(onClickAppleLogin), for: .touchUpInside)
        button.cornerRadius = 29
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
        self.wechatLogin?.startLogin(withAuthstore: AuthStore.shared,
                                 launchCoordinator: launchCoordinator) { [weak self] result in
            switch result {
            case .success:
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
        self.githubLogin?.startLogin(withAuthstore: AuthStore.shared,
                                     launchCoordinator: coordinator, completionHandler: { [weak self] result in
            switch result {
            case .success(let user):
                return
            case .failure(let error):
                self?.showAlertWith(message: error.localizedDescription)
            }
        })
    }
    
    @objc func debugLogin() {
        let data = UserDefaults.standard.data(forKey: "debugUsers") ?? Data()
        var users = (try? JSONDecoder().decode([User].self, from: data)) ?? []
        if users.isEmpty {
            let user = User(name: "常鲜",
                 avatar: URL(string: "https://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83erv2VzvgqJoe40ic0JRYmasAjtJ3uKibIs1TUGfddFlabNOF9aeSVxiaK05tpeEzIwzgVOtZCVqzyvzw/132")!,
                 userUUID: "7f2a9895-f761-4e25-ad34-8e97f03f6fa5",
                 token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6IjdmMmE5ODk1LWY3NjEtNGUyNS1hZDM0LThlOTdmMDNmNmZhNSIsImxvZ2luU291cmNlIjoiV2VDaGF0IiwiaWF0IjoxNjM5NTU4MTIwLCJleHAiOjE2NDIwNjM3MjAsImlzcyI6ImZsYXQtc2VydmVyIn0.ePfvssZOcvtpO3IzoalhHoglvFpSCqzRHbKUhdmbH1I")
            users = [user]
        }
        let alert = UIAlertController(title: "login", message: "debug", preferredStyle: .actionSheet)
        for user in users {
            alert.addAction(.init(title: user.name,
                                  style: .default,
                                  handler: { _ in
                AuthStore.shared.processLoginSuccessUserInfo(user)
            }))
        }
        alert.addAction(.init(title: "cancel", style: .cancel, handler: nil))
        popoverViewController(viewController: alert, fromSource: githubLoginButton)
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
