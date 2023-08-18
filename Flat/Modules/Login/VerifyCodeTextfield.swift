//
//  VerifyCodeTextfield.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class VerifyCodeTextfield: BottomLineTextfield {
    var sendSMSAddtionalCheck: ((_ sender: UIView) -> Result<Void, String>)?
    var smsRequestMaker: (() -> Observable<EmptyResponse>)?
    var smsErrorHandler: ((Error)->Void)?
    var bag = DisposeBag()
    var sendSmsEnable: Observable<Bool>? {
        didSet {
            bag = DisposeBag()
            guard let sendSmsEnable else { return }
            sendSmsEnable
                .subscribe(with: smsButton, onNext: { btn, enable in
                    if enable {
                        btn.setTitleColor(.color(type: .primary), for: .normal)
                    } else {
                        btn.setTitleColor(.color(type: .text, .weak), for: .normal)
                    }
                })
                .disposed(by: bag)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setupViews() {
        super.setupViews()

        placeholder = localizeStrings("VerificationCodePlaceholder")
        font = .systemFont(ofSize: 16)
        keyboardType = .numberPad
        textColor = .color(type: .text)

        leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "veryfication"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .color(type: .text)
        leftContainer.addSubview(leftIcon)
        leftContainer.frame = leftIcon.bounds
        leftView = leftContainer

        rightViewMode = .always
        let smsContainer = UIView()
        smsContainer.frame = .init(origin: .zero, size: .init(width: 100, height: 44))
        smsContainer.addSubview(smsButton)
        smsButton.frame = smsContainer.bounds
        rightView = smsContainer
    }

    // MARK: - Action -

    @objc
    func onClickSendSMS(sender: UIButton) {
        let top = sender.viewController()
        if case let .failure(errStr) = sendSMSAddtionalCheck?(sender) {
            top?.toast(errStr)
            return
        }
        top?.showActivityIndicator()
        smsRequestMaker?()
            .asSingle()
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, _ in
                top?.stopActivityIndicator()
                top?.toast(localizeStrings("CodeSend"))
                weakSelf.startTimer()
            }, onFailure: { ws, err in
                top?.stopActivityIndicator()
                if let handler = ws.smsErrorHandler {
                    handler(err)
                } else {
                    top?.toast(err.localizedDescription)
                }
            })
            .disposed(by: rx.disposeBag)
    }

    @objc
    func startTimer() {
        let count = 60
        smsButton.setTitle("\(count) S", for: .disabled)
        smsButton.isEnabled = false
        Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { count - 1 - $0 }
            .asDriver(onErrorJustReturn: 0)
            .drive(with: smsButton, onNext: { [weak self] btn, c in
                let str = "\(c) S"
                btn.setTitle(str, for: .disabled)
                if c == 0 {
                    self?.rx.disposeBag = DisposeBag()
                }
            }, onCompleted: { btn in
                btn.isEnabled = true
            }, onDisposed: { btn in
                btn.isEnabled = true
            })
            .disposed(by: rx.disposeBag)
    }

    // MARK: - Lazy -

    lazy var smsButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setTitle(localizeStrings("SendSMS"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.color(type: .primary), for: .normal)
        btn.setTitleColor(.color(type: .text, .weak), for: .disabled)
        btn.addTarget(self, action: #selector(onClickSendSMS(sender:)), for: .touchUpInside)
        return btn
    }()
}
