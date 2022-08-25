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
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
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

        let mainView = UIView()
        let stack = UIStackView(arrangedSubviews: [])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        view.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        if !traitCollection.hasCompact {
            let leftView = UIImageView(image: UIImage(named: "login_pad"))
            leftView.contentMode = .scaleAspectFill
            leftView.clipsToBounds = true
            stack.addArrangedSubview(leftView)
        }
        stack.addArrangedSubview(mainView)
        
        if traitCollection.hasCompact {
            
            addPresentTitle(localizeStrings("BindPhone"))
            addPresentCloseButton {
                AuthStore.shared.logout()
            }
            
            mainView.addSubview(smsAuthView)
            smsAuthView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(66)
            }
            
            let bindButton = FlatGeneralCrossButton()
            bindButton.setTitle(NSLocalizedString("Confirm", comment: ""), for: .normal)
            mainView.addSubview(bindButton)
            bindButton.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.top.equalTo(smsAuthView.snp.bottom).offset(28)
            }
            bindButton.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
            
            smsAuthView
                .loginEnable
                .asDriver(onErrorJustReturn: true)
                .drive(bindButton.rx.isEnabled)
                .disposed(by: rx.disposeBag)
        } else {
            mainView.addSubview(smsAuthView)
            smsAuthView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.72)
            }
            
            let bindButton = FlatGeneralCrossButton()
            bindButton.setTitle(NSLocalizedString("Confirm", comment: ""), for: .normal)
            mainView.addSubview(bindButton)
            bindButton.snp.makeConstraints { make in
                make.left.right.equalTo(smsAuthView)
                make.height.equalTo(40)
                make.top.equalTo(smsAuthView.snp.bottom).offset(32)
            }
            bindButton.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
            
            smsAuthView
                .loginEnable
                .asDriver(onErrorJustReturn: true)
                .drive(bindButton.rx.isEnabled)
                .disposed(by: rx.disposeBag)
                
            let titleLabel = UILabel()
            titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
            titleLabel.textColor = .strongText
            titleLabel.text = NSLocalizedString("BindPhone", comment: "")
            mainView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(smsAuthView.snp.top).offset(-100)
            }
            
            let bindPhoneDetailLabel = UILabel()
            bindPhoneDetailLabel.text = localizeStrings("Bind Phone Detail")
            bindPhoneDetailLabel.font = .systemFont(ofSize: 14)
            bindPhoneDetailLabel.textColor = .text
            mainView.addSubview(bindPhoneDetailLabel)
            bindPhoneDetailLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
            }
            
            let closeButton = UIButton(type: .custom)
            closeButton.setTitleColor(.brandColor, for: .normal)
            closeButton.setTitle(localizeStrings("Back"), for: .normal)
            closeButton.titleLabel?.font = .systemFont(ofSize: 14)
            mainView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.size.equalTo(bindButton)
                make.top.equalTo(bindButton.snp.bottom).offset(4)
                make.centerX.equalToSuperview()
            }
            closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        }
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
