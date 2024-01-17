//
//  AccountTextfield.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import PhoneNumberKit

enum AccountType: String, Codable {
    case phone
    case email
    
    func valid(_ text: String, country: Country) -> Bool {
        switch self {
        case .phone:
            let isValid = PhoneNumberKit().isValidPhoneNumber(text, withRegion: country.code)
            return isValid
        case .email:
            return text.isEmail()
        }
    }
}

class AccountTextfield: BottomLineTextfield {
    weak var presentRoot: UIViewController?
    let staticAccountType: AccountType?
    var accountType: BehaviorRelay<AccountType>
    var accountEnable: Observable<Bool> {
        Observable.combineLatest(accountType, rx.text.orEmpty) { [unowned self] type, account in
            type.valid(account, country: country)
        }
    }
    
    var accountText: String {
        switch accountType.value {
        case .phone: return "+\(country.phoneCode)\(text ?? "")"
        case .email: return text ?? ""
        }
    }
    
    var country = Country.currentCountry() {
        didSet {
            countryCodeSelectBtn.setTitle("+\(country.phoneCode)", for: .normal)
        }
    }
    
    func fillWith(countryCode: String?, inputText: String) {
        if let countryCode, let country = Country.countryFor(regionCode: countryCode) {
            self.country = country
        }
        text = inputText
        sendActions(for: .valueChanged)
    }
    
    // MARK: - Life Cycle -
    init(staticAccountType: AccountType? = nil) {
        self.staticAccountType = staticAccountType
        if let staticAccountType {
            self.accountType = .init(value: staticAccountType)
        } else {
            self.accountType = .init(value: Env().preferPhoneAccount ? .phone : .email)
        }
        super.init(frame: .zero)
        binding()
    }
    
    required init?(coder: NSCoder) {
        staticAccountType = nil
        accountType = .init(value: .phone)
        super.init(coder: coder)
        binding()
    }

    override func setupViews() {
        super.setupViews()
        placeholder = localizeStrings("EmailOrPhonePlaceHolder")
        font = .systemFont(ofSize: 16)
        textColor = .color(type: .text)
        leftViewMode = .always
        leftView = leftContainer
        
        if let staticAccountType {
            switch staticAccountType {
            case .phone:
                keyboardType = .numberPad
                placeholder = localizeStrings("PhoneInputPlaceholder")
            case .email:
                keyboardType = .emailAddress
                placeholder = localizeStrings("EmailInputPlaceholder")
            }
        }
    }
    
    // MARK: - Private -
    
    private func binding() {
        if staticAccountType == nil {
            rx.text.orEmpty
                .filter(\.isNotEmptyOrAllSpacing)
                .map { $0.allSatisfy({ c in c.isNumber }) }
                .distinctUntilChanged()
                .subscribe(with: self) { ws, isPhone in
                    ws.accountType.accept(isPhone ? .phone : .email)
                }
                .disposed(by: rx.disposeBag)
        }
        
        accountType
            .subscribe(with: self) { ws, type in
                ws.update(accountType: type)
            }
            .disposed(by: rx.disposeBag)
    }
    
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
        leftView = leftContainer
    }
    
    // MARK: - Action -
    @objc
    func onClickCountryCode() {
        presentRoot?.present(picker, animated: true)
    }
    
    // MARK: - Lazy -
    lazy var leftContainer: UIView = {
        let view = UIView()
        view.addSubview(countryCodeSelectBtn)
        view.addSubview(emailIcon)
        return view
    }()
    
    lazy var emailIcon: UIImageView = {
        let view = UIImageView(image: UIImage(named: "email_icon"))
        view.frame = .init(origin: .zero, size: .init(width: 30, height: 44))
        view.contentMode = .center
        view.tintColor = .color(type: .text)
        return view
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
}
