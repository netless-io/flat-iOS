//
//  SMSAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2022/4/13.
//  Copyright © 2022 agora.io. All rights reserved.
//

import PhoneNumberKit
import RxCocoa
import RxSwift
import UIKit

class SMSAuthView: UIView {
    weak var presentRoot: UIViewController?

    func fillWith(phone: String) {
        phoneTextfield.text = phone
        phoneTextfield.sendActions(for: .valueChanged)
    }
    
    private var country = Country.currentCountry() {
        didSet {
            countryCodeSelectBtn.setTitle("+\(country.phoneCode)", for: .normal)
        }
    }

    private var phoneValid: Bool {
        guard let text = phoneTextfield.text else { return false }
        let isValid = PhoneNumberKit().isValidPhoneNumber(text, withRegion: country.code)
        return isValid
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
        verificationCodeTextfield.sendSmsEnable = phoneTextfield.rx.text.orEmpty
            .map { [unowned self] _ in self.phoneValid }
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

    lazy var verificationCodeTextfield: VerifyCodeTextfield = {
        let tf = VerifyCodeTextfield()
        tf.requireCaptchaVerifyParam = true
        return tf
    }()
}
