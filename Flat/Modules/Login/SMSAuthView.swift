//
//  SMSAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class SMSAuthView: UIView {
    var availableCountryCodes: [Int] = [86]
    var countryCode = 86 {
        didSet {
            countryCodeSelectBtn.setTitle("+\(countryCode)", for: .normal)
        }
    }

    var smsRequestMaker: ((String) -> Observable<EmptyResponse>)?
    var additionalCheck: ((_ sender: UIView) -> Result<Void, String>)?
    var phoneRegex: String = "1[3456789]\\d{9}$"
    var phoneValid: Bool { (try? phoneTextfield.text?.matchExpressionPattern(phoneRegex) != nil) ?? false }
    var fullPhoneText: String { "+\(countryCode)\(phoneTextfield.text ?? "")" }
    var codeText: String { verificationCodeTextfield.text ?? "" }
    var codeValid: Bool { codeText.count >= 4 }
    var loginEnable: Observable<Bool> {
        Observable.combineLatest(phoneTextfield.rx.text.orEmpty,
                                 verificationCodeTextfield.rx.text.orEmpty) { [unowned self] _, _ in
            self.phoneValid && self.codeValid
        }
    }

    func allValidCheck(sender: UIView?) -> Result<Void, String> {
        if let additionalCheck {
            switch additionalCheck(sender ?? self) {
            case .success: break
            case let .failure(errorStr):
                return .failure(errorStr)
            }
        }
        if !phoneValid { return .failure(localizeStrings("InvalidPhone")) }
        if !codeValid { return .failure(localizeStrings("InvalidCode")) }
        return .success(())
    }

    @objc
    func onClickCountryCode() {}

    @objc
    func onClickSendSMS(sender: UIButton) {
        let top = sender.viewController()
        if case let .failure(errStr) = additionalCheck?(sender) {
            top?.toast(errStr)
            return
        }
        guard phoneValid else {
            top?.toast(localizeStrings("InvalidPhone"))
            return
        }
        top?.showActivityIndicator()
        smsRequestMaker?(fullPhoneText)
            .asSingle()
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, _ in
                top?.stopActivityIndicator()
                top?.toast(localizeStrings("CodeSend"))
                weakSelf.startTimer()
            }, onFailure: { _, err in
                top?.stopActivityIndicator()
                top?.toast(err.localizedDescription)
            })
            .disposed(by: rx.disposeBag)
    }

    override init(frame _: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        backgroundColor = .color(type: .background)

        let margin: CGFloat = 16
        let textfieldHeight: CGFloat = 44
        let stackView = UIStackView(arrangedSubviews: [phoneTextfield])
        stackView.axis = .vertical
        stackView.distribution = .fill
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let g0 = UIView()
        stackView.addArrangedSubview(g0)
        g0.snp.makeConstraints { make in
            make.height.equalTo(margin)
        }
        stackView.addArrangedSubview(verificationCodeTextfield)

        phoneTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        verificationCodeTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
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

    override var intrinsicContentSize: CGSize {
        .init(width: 375, height: 0)
    }

    lazy var verificationCodeTextfield: BottomLineTextfield = {
        let f = BottomLineTextfield()
        f.placeholder = localizeStrings("VerificationCodePlaceholder")
        f.font = .systemFont(ofSize: 16)
        f.keyboardType = .numberPad
        f.textColor = .color(type: .text)

        f.leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "veryfication"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .color(type: .text)
        leftContainer.addSubview(leftIcon)
        leftContainer.frame = leftIcon.bounds
        f.leftView = leftContainer

        f.rightViewMode = .always
        let smsContainer = UIView()
        smsContainer.frame = .init(origin: .zero, size: .init(width: 100, height: 44))
        smsContainer.addSubview(self.smsButton)
        self.smsButton.frame = smsContainer.bounds
        f.rightView = smsContainer
        return f
    }()

    lazy var countryCodeSelectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.frame = .init(origin: .zero, size: .init(width: 66, height: 48))
        btn.setTitle("+\(countryCode)", for: .normal)
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.setImage(UIImage(named: "arrow_down"), for: .normal)
        btn.titleEdgeInsets = .init(top: 0, left: -20, bottom: 0, right: 20)
        btn.imageEdgeInsets = .init(top: 0, left: 40, bottom: 0, right: 0)
        btn.tintColor = .color(type: .text)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(onClickCountryCode), for: .touchUpInside)
        return btn
    }()

    lazy var phoneTextfield: BottomLineTextfield = {
        let f = BottomLineTextfield()
        f.placeholder = localizeStrings("PhoneInputPlaceholder")
        f.keyboardType = .phonePad
        f.font = .systemFont(ofSize: 16)
        f.textColor = .color(type: .text)

        f.leftViewMode = .always
        let leftContainer = UIView()
        leftContainer.frame = self.countryCodeSelectBtn.bounds
        leftContainer.addSubview(self.countryCodeSelectBtn)
        f.leftView = leftContainer
        return f
    }()

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
