//
//  LoginViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class LoginViewController: UIViewController {
    var wechatLogin: WechatLogin?
    var githunLogin: GithubLogin?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .compact {
            return [.portrait]
        } else {
            return [.all]
        }
    }
    
    deinit {
        print(self, "deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide wechat login when wechat not installed
        wechatLoginButton.isHidden = !WXApi.isWXAppInstalled()
        syncTraiCollection(traitCollection)
        #if DEBUG
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(debugLogin))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        #endif
    }
    
    func syncTraiCollection(_ trait: UITraitCollection) {
        if trait.horizontalSizeClass == .compact || trait.verticalSizeClass == .compact {
            loginBg.isHidden = true
        } else {
            loginBg.isHidden = false
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        syncTraiCollection(traitCollection)
    }
    
    @IBAction func onClickWechatButton(_ sender: Any) {
        guard let launchCoordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        self.wechatLogin = WechatLogin()
        self.wechatLogin?.startLogin(withAuthstore: AuthStore.shared,
                                 launchCoordinator: launchCoordinator) { [weak self] result in
            switch result {
            case .success:
                return
            case .failure(let error):
                self?.showAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func onClickGithubButton(_ sender: Any) {
        guard let coordinator = globalLaunchCoordinator else { return }
        showActivityIndicator(forSeconds: 1)
        self.githunLogin = GithubLogin()
        self.githunLogin?.startLogin(withAuthstore: AuthStore.shared,
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
        let users: [User] = [.init(name: "常鲜",
                                   avatar: .init(string: "https://thirdwx.qlogo.cn/mmopen/vi_32/DYAIOgq83erv2VzvgqJoe40ic0JRYmasAjtJ3uKibIs1TUGfddFlabNOF9aeSVxiaK05tpeEzIwzgVOtZCVqzyvzw/132")!,
                                   userUUID: "7f2a9895-f761-4e25-ad34-8e97f03f6fa5",
                                   token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6IjdmMmE5ODk1LWY3NjEtNGUyNS1hZDM0LThlOTdmMDNmNmZhNSIsImxvZ2luU291cmNlIjoiV2VDaGF0IiwiaWF0IjoxNjM2NTkyODk1LCJleHAiOjE2MzkwOTg0OTUsImlzcyI6ImZsYXQtc2VydmVyIn0.M4g2hacIV7jo5FxbCRjWne_zE1bQiklSGN1dIrItwyw"),
                             .init(name: "xuyunshi",
                                   avatar: .init(string: "https://avatars.githubusercontent.com/u/26054167?s=400&u=85a3730ee7fbc435b64c67f09ca69f5fb223223a&v=4")!,
                                   userUUID: "5e724ca3-a86c-4672-a1f9-11fac914ac09",
                                   token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6IjVlNzI0Y2EzLWE4NmMtNDY3Mi1hMWY5LTExZmFjOTE0YWMwOSIsImxvZ2luU291cmNlIjoiR2l0aHViIiwiaWF0IjoxNjM2NjEwNjI3LCJleHAiOjE2MzkxMTYyMjcsImlzcyI6ImZsYXQtc2VydmVyIn0.0PQCbNi-UGuG2XnF8QFD5hHKqvBg0iZpFy0bdPXEBQQ"),
                             .init(name: "xysT2W",
                                   avatar: .init(string: "https://avatars.githubusercontent.com/u/67670791?v=4")!,
                                   userUUID: "9dec6d84-ca9a-4333-9cf6-a19734768e3a",
                                   token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVVVJRCI6IjlkZWM2ZDg0LWNhOWEtNDMzMy05Y2Y2LWExOTczNDc2OGUzYSIsImxvZ2luU291cmNlIjoiR2l0aHViIiwiaWF0IjoxNjM2NTk4OTgzLCJleHAiOjE2MzkxMDQ1ODMsImlzcyI6ImZsYXQtc2VydmVyIn0.JzEF6PeNr3PY2aASEWJuzskz5AFk90QiUH6BC0jaC60")
        ]
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
    
    @IBOutlet weak var loginBg: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var githubLoginButton: UIButton!
    @IBOutlet weak var wechatLoginButton: UIButton!
}
