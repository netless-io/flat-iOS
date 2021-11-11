//
//  LoginViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class LoginViewController: UIViewController {
    var githunLogin: GithubLogin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: hide wechat when wx not intsalled
        syncTraiCollection(traitCollection)
    }
    
    func syncTraiCollection(_ trait: UITraitCollection) {
        switch trait.horizontalSizeClass {
        case .compact:
            stackView.axis = .vertical
        case .regular:
            stackView.axis = .horizontal
        case .unspecified:
            return
        @unknown default:
            return
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        syncTraiCollection(traitCollection)
    }
    
    @IBAction func onClickWechatButton(_ sender: Any) {
    }
    
    @IBAction func onClickGithubButton(_ sender: Any) {
        showActivityIndicator(forSeconds: 1)
        AuthStore.shared.startGithubLogin { result in
            switch result {
            case .success(let user):
                print(user)
                return
            case .failure(let error):
                self.showAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var githubLoginButton: UIButton!
    @IBOutlet weak var wechatLoginButton: UIButton!
}
