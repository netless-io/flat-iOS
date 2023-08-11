//
//  SMSAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import libPhoneNumber_iOS
import RxCocoa
import RxSwift
import UIKit

class SMSAuthView: UIView {
    weak var presentRoot: UIViewController?
    var sendSMSAddtionalCheck: ((_ sender: UIView) -> Result<Void, String>)?
    var smsRequestMaker: ((String) -> Observable<EmptyResponse>)?
    
    private var country = Country.currentCountry() {
        didSet {
            countryCodeSelectBtn.setTitle("+\(country.phoneCode)", for: .normal)
        }
    }
    private var phoneValid: Bool {
        guard let text = phoneTextfield.text else { return false }
        guard let phoneObj = try? NBPhoneNumberUtil.sharedInstance().parse(text, defaultRegion: country.code) else { return false }
        return NBPhoneNumberUtil.sharedInstance().isValidNumber(forRegion: phoneObj, regionCode: country.code)
    }
    private var codeValid: Bool { codeText.count >= 4 }

    var fullPhoneText: String { "+\(country.phoneCode)\(phoneTextfield.text ?? "")" }
    var codeText: String { verificationCodeTextfield.text ?? "" }
    var loginEnable: Observable<Bool> {
        Observable.combineLatest(phoneTextfield.rx.text.orEmpty,
                                 verificationCodeTextfield.rx.text.orEmpty)
        { [unowned self] _, _ in
            self.phoneValid && self.codeValid
        }
    }

    @objc
    func onClickCountryCode() {
        presentRoot?.present(picker, animated: true)
    }

    @objc
    func onClickSendSMS(sender: UIButton) {
        let top = sender.viewController()
        if case let .failure(errStr) = sendSMSAddtionalCheck?(sender) {
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
        binding()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        binding()
    }
    
    override var intrinsicContentSize: CGSize {
        .init(width: 375, height: UIView.noIntrinsicMetric)
    }

    func binding() {
        phoneTextfield.rx.text.orEmpty
            .map { [unowned self] _ in self.phoneValid }
            .subscribe(with: smsButton, onNext: { btn, enable in
                if enable {
                    btn.setTitleColor(.color(type: .primary), for: .normal)
                } else {
                    btn.setTitleColor(.color(type: .text, .weak), for: .normal)
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    private func setupViews() {
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

    lazy var picker: UIViewController = {
        let picker = CountryCodePicker()
        picker.pickingHandler = { [weak self] country in
            self?.presentRoot?.dismiss(animated: true)
            self?.country = country
        }
        let navi = BaseNavigationViewController(rootViewController: picker)
        navi.modalPresentationStyle = .formSheet
        return navi
    }()
    
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
        let btn = UIButton(type: .system)
        btn.frame = .init(origin: .zero, size: .init(width: 66, height: 48))
        btn.setTitle("+\(country.phoneCode)", for: .normal)
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
