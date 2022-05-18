//
//  PrivacyAlertViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/5/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class PrivacyAlertViewController: UIViewController {
    internal init(privacyClick: @escaping (() -> Void),
                  agreementClick: @escaping (() -> Void),
                  agreeClick: @escaping (() -> Void),
                  cancelClick: @escaping (() -> Void)) {
        self.privacyClick = privacyClick
        self.agreementClick = agreementClick
        self.agreeClick = agreeClick
        self.cancelClick = cancelClick
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let privacyClick: (()->Void)
    let agreementClick: (()->Void)
    let agreeClick: (()->Void)
    let cancelClick: (()->Void)
    
    @IBOutlet weak var buttonStack: UIStackView!
    lazy var serviceBtn: UIButton = UIButton(type: .system)
    lazy var privacyBtn: UIButton = UIButton(type: .system)
    @IBOutlet weak var mainBgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.textColor = .text
        mainBgView.backgroundColor = .whiteBG
        buttonStack.addArrangedSubview(privacyBtn)
        buttonStack.addArrangedSubview(serviceBtn)
        privacyBtn.setTitle(pretty(agreementTitle: NSLocalizedString("Privacy Policy", comment: "")), for: .normal)
        serviceBtn.setTitle(pretty(agreementTitle: NSLocalizedString("Service Agreement", comment: "")), for: .normal)
        privacyBtn.addTarget(self, action: #selector(onClickPrivacy(_:)), for: .touchUpInside)
        serviceBtn.addTarget(self, action: #selector(onClickService(_:)), for: .touchUpInside)
        privacyBtn.titleLabel?.font = .systemFont(ofSize: 14)
        serviceBtn.titleLabel?.font = .systemFont(ofSize: 14)
        
        let btn = UIButton(type: .custom)
        view.insertSubview(btn, at: 0)
        btn.addTarget(self, action: #selector(onClickReject(_:)), for: .touchUpInside)
        btn.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    func pretty(agreementTitle: String)-> String { return "《\(agreementTitle)》" }
    
    @objc func onClickPrivacy(_ sender: Any) {
        privacyClick()
    }
    
    @objc func onClickService(_ sender: Any) {
        agreementClick()
    }
    
    @IBAction func onClickAgree(_ sender: Any) {
        agreeClick()
    }
    
    @IBAction func onClickReject(_ sender: Any) {
        cancelClick()
    }
}
