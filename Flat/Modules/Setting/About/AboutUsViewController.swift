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
    @IBOutlet weak var libButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        if Env().region == .CN {
            let beianButton = UIButton(type: .system)
            beianButton.setTitle("沪ICP备14053584号-25A >", for: .normal)
            beianButton.titleLabel?.font = .systemFont(ofSize: 12)
            beianButton.addTarget(self, action: #selector(onClickBeian), for: .touchUpInside)
            view.addSubview(beianButton)
            beianButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(libButton.snp.top).offset(-10)
            }
        }
    }

    @objc func onClickBeian(_ sender: Any) {
        let controller = SFSafariViewController(url: .init(string: "https://beian.miit.gov.cn")!)
        present(controller, animated: true, completion: nil)
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
        guard let url = Env().privacyURL else { return }
        let controller = SFSafariViewController(url: url)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func onClickServiceAgreement(_: Any) {
        guard let url = Env().serviceURL else { return }
        let controller = SFSafariViewController(url: url)
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
