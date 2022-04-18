//
//  SMSAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SMSAuthView: UIView {
    var availableCountryCodes: [Int] = [86]
    var countryCode = 86 {
        didSet {
            countryCodeSelectBtn.setTitle("+\(countryCode)", for: .normal)
        }
    }
    var smsRequestMaker: ((String)->Observable<Dictionary<String, String>>)?
    var additionalCheck: (()->Result<Void, String>)?
    var phoneRegex: String = "1[3456789]\\d{9}$"
    var phoneValid: Bool { (try? phoneTextfield.text?.matchExpressionPattern(phoneRegex) != nil) ?? false }
    var fullPhoneText: String { "+\(countryCode)\(phoneTextfield.text ?? "")"}
    var codeText: String { verificationCodeTextfield.text ?? "" }
    var codeValid: Bool { !codeText.isEmpty }
    
    func allValidCheck() -> Result<Void, String> {
        if let additionalCheck = additionalCheck {
            switch additionalCheck() {
            case .success: break
            case .failure(let errorStr):
                return .failure(errorStr)
            }
        }
        if !phoneValid { return .failure(NSLocalizedString("InvalidPhone", comment: "")) }
        if !codeValid { return .failure(NSLocalizedString("InvalidCode", comment: "")) }
        return .success(())
    }
    
    @objc
    func onClickCountryCode() {
    }
    
    @objc
    func onClickSendSMS() {
        let top = UIApplication.shared.topViewController
        if case .failure(let errStr) = additionalCheck?() {
            top?.toast(errStr)
            return
        }
        guard phoneValid else {
            top?.toast(NSLocalizedString("InvalidPhone", comment: ""))
            return
        }
        top?.showActivityIndicator()
        smsRequestMaker?(fullPhoneText)
            .asSingle()
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self, onSuccess: { weakSelf, _ in
                top?.stopActivityIndicator()
                top?.toast(NSLocalizedString("CodeSend", comment: ""))
                weakSelf.startTimer()
            }, onFailure: { weakSelf, err in
                top?.stopActivityIndicator()
                top?.toast(err.localizedDescription)
            })
            .disposed(by: rx.disposeBag)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    func setupViews() {
        backgroundColor = .whiteBG
        
        let margin: CGFloat = 16
        let textfieldHeight: CGFloat = 44
        let stackView = UIStackView(arrangedSubviews: [phonePlaceHolder, phoneTextfield, phoneLine])
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
        stackView.addArrangedSubview(verificationCodePlaceHolder)
        stackView.addArrangedSubview(verificationCodeTextfield)
        stackView.addArrangedSubview(verificationCodeLine)
        
        phoneTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        verificationCodeTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        phoneLine.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
        verificationCodeLine.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
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
        return .init(width: 375, height: 0)
    }
    
    lazy var verificationCodeTextfield: UITextField = {
        let f = UITextField()
        f.placeholder = NSLocalizedString("VerificationCodePlaceholder", comment: "")
        f.font = .systemFont(ofSize: 16)
        f.keyboardType = .numberPad
        f.textColor = .text
        
        f.leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "veryfication"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .text
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
        btn.setTitle("+ \(countryCode)", for: .normal)
        btn.setTitleColor(.text, for: .normal)
        btn.setImage(UIImage(named: "arrow_down"), for: .normal)
        btn.titleEdgeInsets = .init(top: 0, left: -15, bottom: 0, right: 15)
        btn.imageEdgeInsets = .init(top: 0, left: 50, bottom: 0, right: 0)
        btn.tintColor = .text
        btn.addTarget(self, action: #selector(onClickCountryCode), for: .touchUpInside)
        return btn
    }()
    
    lazy var phoneTextfield: UITextField = {
        let f = UITextField()
        f.placeholder = NSLocalizedString("PhoneInputPlaceholder", comment: "")
        f.keyboardType = .phonePad
        f.font = .systemFont(ofSize: 16)
        f.textColor = .text
        
        f.leftViewMode = .always
        let leftContainer = UIView()
        leftContainer.frame = self.countryCodeSelectBtn.bounds
        leftContainer.addSubview(self.countryCodeSelectBtn)
        f.leftView = leftContainer
        return f
    }()
    
    lazy var phonePlaceHolder:UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("PhoneNumber", comment: "")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .subText
        return label
    }()
    
    lazy var phoneLine: UIView =  {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    lazy var verificationCodePlaceHolder:UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("VerificationCode", comment: "")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .subText
        return label
    }()
    
    lazy var verificationCodeLine: UIView =  {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    lazy var smsButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setTitle(NSLocalizedString("SendSMS", comment: ""), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.brandColor, for: .normal)
        btn.setTitleColor(.subText, for: .disabled)
        btn.addTarget(self, action: #selector(onClickSendSMS), for: .touchUpInside)
        return btn
    }()
}
