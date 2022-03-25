//
//  AboutUsViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import SafariServices
import AcknowList

class AboutUsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        title = NSLocalizedString("About", comment: "")
        view.backgroundColor = .whiteBG
        flatLabel.textColor = .text
        versionLabel.text = "Version \(Env().version)"
    }
    
    @IBAction func onClickPrivacyPolicy(_ sender: Any) {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/privacy.html")!)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func onClickServiceAgreement(_ sender: Any) {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/service.html")!)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func onClickAcknowledgement(_ sender: Any) {
        guard let path = Bundle.main.path(forResource: "Pods-Flat-acknowledgements", ofType: "plist")
        else { return }
        let vc = AcknowListViewController(plistPath: path)
        present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    @IBOutlet weak var flatLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
}
