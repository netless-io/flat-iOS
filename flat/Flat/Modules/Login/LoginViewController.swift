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
    var githubLogin: GithubLogin?
    
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
        syncTraitCollection(traitCollection)
        #if DEBUG
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(debugLogin))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        #endif
    }
    
    func syncTraitCollection(_ trait: UITraitCollection) {
        if trait.horizontalSizeClass == .compact || trait.verticalSizeClass == .compact {
            loginBg.isHidden = true
        } else {
            loginBg.isHidden = false
        }
    }
    
    @IBAction func onClickWechatButton(_ sender: Any) {
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
                self?.showAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func onClickGithubButton(_ sender: Any) {
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
        guard let data = UserDefaults.standard.data(forKey: "debugUsers"),
              let users = try? JSONDecoder().decode([User].self, from: data), !users.isEmpty else {
                  return
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
    
    @IBOutlet weak var loginBg: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var githubLoginButton: UIButton!
    @IBOutlet weak var wechatLoginButton: UIButton!
}
