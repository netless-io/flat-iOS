//
//  PasswordAuthView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/10.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import libPhoneNumber_iOS

class PasswordAuthView: UIView {
    enum AccountType {
        case phone
        case email
        
        func valid(_ text: String, country: Country) -> Bool {
            switch self {
            case .phone:
                guard let phoneObj = try? NBPhoneNumberUtil.sharedInstance().parse(text, defaultRegion: country.code) else { return false }
                return NBPhoneNumberUtil.sharedInstance().isValidNumber(forRegion: phoneObj, regionCode: country.code)
            case .email:
                return text.isEmail()
            }
        }
    }
    weak var presentRoot: UIViewController?
    
    var accountType: BehaviorRelay<AccountType> = .init(value: .phone)
    
    var accountText: String {
        switch accountType.value {
        case .phone: return "+\(country.phoneCode)\(accountTextfield.text ?? "")"
        case .email: return accountTextfield.text ?? ""
        }
    }
    
    var passwordText: String {
        passwordTextfield.text ?? ""
    }
    
    var loginEnable: Observable<Bool> {
        Observable.combineLatest(
            accountType.asObservable(),
            accountTextfield.rx.text.orEmpty,
            passwordTextfield.rx.text.orEmpty)
        { [unowned self] type, account, pwd in
            type.valid(account, country: country) && !pwd.isEmpty
        }
    }
    
    private var country = Country.currentCountry() {
        didSet {
            countryCodeSelectBtn.setTitle("+\(country.phoneCode)", for: .normal)
        }
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
    
    private func binding() {
        accountTextfield.rx.text.orEmpty
            .map { $0.allSatisfy({ c in c.isNumber }) }
            .distinctUntilChanged()
            .subscribe(with: self) { ws, isPhone in
                ws.accountType.accept(isPhone ? .phone : .email)
            }
            .disposed(by: rx.disposeBag)
        
        accountType
            .subscribe(with: self) { ws, type in
                ws.update(accountType: type)
            }
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Private -
    
    func update(accountType: AccountType, animated: Bool = true) {
        switch accountType {
        case .email:
            leftContainer.frame = emailIcon.bounds
            emailIcon.isHidden = false
            countryCodeSelectBtn.isHidden = true
            
            if animated {
                leftContainer.transform = .init(translationX: 10, y: 0)
                UIView.animate(withDuration: 0.3) {
                    self.leftContainer.transform = .identity
                }
            }
        case .phone:
            leftContainer.frame = countryCodeSelectBtn.bounds
            emailIcon.isHidden = true
            countryCodeSelectBtn.isHidden = false
            if animated {
                leftContainer.transform = .init(translationX: -100, y: 0)
                UIView.animate(withDuration: 0.3) {
                    self.leftContainer.transform = .identity
                }
            }
        }
        self.accountTextfield.leftView = self.leftContainer
    }
    
    private func setupViews() {
        backgroundColor = .color(type: .background)

        let margin: CGFloat = 16
        let textfieldHeight: CGFloat = 44
        let stackView = UIStackView(arrangedSubviews: [accountTextfield])
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
        stackView.addArrangedSubview(passwordTextfield)

        accountTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
        passwordTextfield.snp.makeConstraints { $0.height.equalTo(textfieldHeight) }
    }
    
    @objc
    func onClickCountryCode() {
        presentRoot?.present(picker, animated: true)
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
    
    lazy var accountTextfield: BottomLineTextfield = {
        let f = BottomLineTextfield()
        f.placeholder = localizeStrings("EmailOrPhonePlaceHolder")
        f.font = .systemFont(ofSize: 16)
        f.textColor = .color(type: .text)
        f.leftViewMode = .always
        f.leftView = leftContainer
        return f
    }()
    
    lazy var emailIcon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "email_icon"))
        view.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        view.contentMode = .center
        view.tintColor = .color(type: .text)
        return view
    }()
    
    lazy var leftContainer: UIView = {
        let view = UIView()
        view.addSubview(countryCodeSelectBtn)
        view.addSubview(emailIcon)
        return view
    }()
    
    lazy var passwordTextfield: BottomLineTextfield = {
        let f = BottomLineTextfield()
        f.placeholder = localizeStrings("PassCodePlaceholder")
        f.font = .systemFont(ofSize: 16)
        f.textColor = .color(type: .text)
        f.isSecureTextEntry = true

        f.leftViewMode = .always
        let leftContainer = UIView()
        let leftIcon = UIImageView(image: UIImage(named: "password_icon"))
        leftIcon.contentMode = .center
        leftIcon.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        leftIcon.tintColor = .color(type: .text)
        leftContainer.addSubview(leftIcon)
        leftContainer.frame = leftIcon.bounds
        f.leftView = leftContainer

        f.rightViewMode = .always
        let secretModeContainer = UIView()
        secretModeContainer.frame = .init(origin: .zero, size: .init(width: 44, height: 44))
        secretModeContainer.addSubview(self.secretModeButton)
        self.secretModeButton.frame = secretModeContainer.bounds
        f.rightView = secretModeContainer
        
        DispatchQueue.main.async {
            self.syncSecretMode()
        }
        return f
    }()
    
    private func syncSecretMode() {
        secretModeButton.setImage(UIImage(named: passwordTextfield.isSecureTextEntry ? "secure_keyboard" : "no_secure_keyboard"), for: .normal)
    }
    @objc func onClickSecret() {
        passwordTextfield.isSecureTextEntry.toggle()
        syncSecretMode()
    }
    lazy var secretModeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "secure_keyboard"), for: .normal)
        btn.addTarget(self, action: #selector(onClickSecret), for: .touchUpInside)
        btn.tintColor = .color(type: .text)
        return btn
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
}
