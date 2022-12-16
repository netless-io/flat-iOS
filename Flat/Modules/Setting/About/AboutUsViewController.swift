//
//  AboutUsViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AcknowList
import SafariServices
import UIKit
import Whiteboard

class AboutUsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }

    @objc func onTap() {
        versionLabel.text = versionLabel.text == "v\(Env().version) (\(Env().build))" ? "Whiteboard v\(WhiteSDK.version())" : "v\(Env().version) (\(Env().build))"
    }

    func setupViews() {
        title = localizeStrings("About")
        view.backgroundColor = .color(type: .background)
        flatLabel.textColor = .color(type: .text)
        versionLabel.text = "v\(Env().version) (\(Env().build))"
    }

    @IBAction func onClickPrivacyPolicy(_: Any) {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/privacy.html")!)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func onClickServiceAgreement(_: Any) {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/service.html")!)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func onClickAcknowledgement(_: Any) {
        guard let path = Bundle.main.path(forResource: "Pods-Flat-acknowledgements", ofType: "plist")
        else { return }
        let vc = AcknowListViewController(plistFileURL: URL(fileURLWithPath: path), style: .grouped)
        present(BaseNavigationViewController(rootViewController: vc), animated: true)
    }

    @IBOutlet var flatLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!
}
