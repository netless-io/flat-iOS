//
//  BindPhoneViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class BindPhoneViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
    }
    
    func setupViews() {
        view.backgroundColor = .whiteBG
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .text
        titleLabel.text = NSLocalizedString("BindPhone", comment: "")
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
        }
        
            
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "close-bold"), for: .normal)
        closeButton.tintColor = .text
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(44)
        }
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        
        view.addSubview(smsAuthView)
        smsAuthView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(66)
            make.left.right.equalToSuperview().inset(16)
        }
        
        let bindButton = FlatGeneralCrossButton()
        bindButton.setTitle(NSLocalizedString("Confirm", comment: ""), for: .normal)
        view.addSubview(bindButton)
        bindButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        bindButton.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
    }
    
    @objc
    func onClose() {
        AuthStore.shared.logout()
    }
    
    @objc
    func onLogin(sender: UIButton) {
        if case .failure(let errStr) = smsAuthView.allValidCheck(sender: sender) {
            toast(errStr)
            return
        }
        let request = BindingPhoneRequest(phone: smsAuthView.fullPhoneText, code: smsAuthView.codeText)
        let activity = showActivityIndicator()
        ApiProvider.shared.request(fromApi: request) { [weak self] result in
            activity.stopAnimating()
            switch result {
            case .success:
                AuthStore.shared.processBindPhoneSuccess()
            case .failure(let error):
                self?.toast(error.localizedDescription)
            }
        }
    }
    
    lazy var smsAuthView: SMSAuthView = {
        let view = SMSAuthView()
        view.smsRequestMaker = { phone in
            return ApiProvider.shared.request(fromApi: SMSRequest(scenario: .bind, phone: phone))
        }
        return view
    }()
}
