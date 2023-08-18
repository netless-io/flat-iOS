//
//  SetNewPasswordViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/17.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import RxSwift

class SetNewPasswordViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        binding()
    }

    func setupViews() {
        title = localizeStrings("SettingNewPassword")
        view.backgroundColor = .color(type: .background)
        view.addSubview(mainContentView)
        mainContentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().inset(16).priority(.medium)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(14)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.snp.bottom).inset(16).priority(.medium)
        }
    }
    
    func binding() {
        Observable.combineLatest(
            p1.rx.text.orEmpty,
            p2.rx.text.orEmpty
        ) { [$0, $1].allSatisfy(\.isNotEmptyOrAllSpacing) }
        .asDriver(onErrorJustReturn: false)
        .drive(updateButton.rx.isEnabled)
        .disposed(by: rx.disposeBag)
    }
    
    @objc
    func onReset() {
        let new = p1.passwordText
        let request = UpdatePasswordRequest(type: .new(new))
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: request) { [weak self] result in
            guard let self else { return }
            self.stopActivityIndicator()
            switch result {
            case .success:
                AuthStore.shared.user?.hasPassword = true
                LoginViewController.lastAccountLoginPwd = new
                self.toast(localizeStrings("Success"), timeInterval: 2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self else { return }
                    self.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
            
        }
    }

    lazy var mainContentView: UIStackView = {
        let spacer = UIView()
        let view = UIStackView(arrangedSubviews: [p1, p2, spacer, updateButton, resetTipsLabel])
        view.axis = .vertical
        view.spacing = 16
        [p1, p2, updateButton].forEach { $0.snp.makeConstraints { make in
            make.height.equalTo(44)
        }}
        resetTipsLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        return view
    }()
    
    lazy var updateButton: FlatGeneralCrossButton = {
        let btn = FlatGeneralCrossButton()
        btn.setTitle(localizeStrings("Confirm"), for: .normal)
        btn.addTarget(self, action: #selector(onReset))
        return btn
    }()
    
    lazy var p1: PasswordTextfield = {
        let tf = PasswordTextfield()
        tf.placeholder = localizeStrings("ResetPasswordPlaceholder")
        return tf
    }()
    
    lazy var p2: PasswordTextfield = {
        let tf = PasswordTextfield()
        tf.placeholder = localizeStrings("ResetPasswordPlaceholderAgain")
        return tf
    }()
    
    lazy var resetTipsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .color(type: .text, .weak)
        label.textAlignment = .center
        label.text = localizeStrings("ResetPasswordTips")
        return label
    }()
}
