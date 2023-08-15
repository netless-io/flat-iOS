//
//  AgreementCheckView.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/15.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import SafariServices

class AgreementCheckView: UIStackView {
    var isSelected: Bool {
        get {
            agreementCheckButton.isSelected
        }
        set {
            agreementCheckButton.isSelected =  newValue
        }
    }
    
    weak var presentRoot: UIViewController?
    init(presentRoot: UIViewController) {
        self.presentRoot = presentRoot
        super.init(frame: .zero)
        setupViews()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Action -
    @objc func onClickPrivacy() {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/privacy.html")!)
        presentRoot?.present(controller, animated: true, completion: nil)
    }

    @objc func onClickServiceAgreement() {
        let controller = SFSafariViewController(url: .init(string: "https://flat.whiteboard.agora.io/service.html")!)
        presentRoot?.present(controller, animated: true, completion: nil)
    }
    
    @objc func onClickAgreement(sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    private func setupViews() {
        let privacyButton = UIButton(type: .custom)
        privacyButton.tintColor = .color(type: .primary)
        privacyButton.setTitleColor(.color(type: .primary), for: .normal)
        privacyButton.titleLabel?.font = .systemFont(ofSize: 12)
        privacyButton.setTitle(localizeStrings("Privacy Policy"), for: .normal)
        privacyButton.addTarget(self, action: #selector(onClickPrivacy), for: .touchUpInside)

        let serviceAgreementButton = UIButton(type: .custom)
        serviceAgreementButton.tintColor = .color(type: .primary)
        serviceAgreementButton.titleLabel?.font = .systemFont(ofSize: 12)
        serviceAgreementButton.setTitle(localizeStrings("Service Agreement"), for: .normal)
        serviceAgreementButton.setTitleColor(.color(type: .primary), for: .normal)
        serviceAgreementButton.addTarget(self, action: #selector(onClickServiceAgreement), for: .touchUpInside)

        let label1 = UILabel()
        label1.textColor = .color(type: .text)
        label1.font = .systemFont(ofSize: 12)
        label1.text = " " + localizeStrings("and") + " "
        label1.setContentCompressionResistancePriority(.required, for: .horizontal) // Don't compress it.

        let space1 = UIView()
        let space2 = UIView()
        space1.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        space2.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        axis = .horizontal
        distribution = .fill
        alignment = .center
        
        [space1, agreementCheckButton, privacyButton, label1, serviceAgreementButton, space2]
            .forEach { addArrangedSubview($0) }
        space2.snp.makeConstraints { make in
            make.width.equalTo(space1)
        }
    }
    
    lazy var agreementCheckButton: UIButton = {
        let btn = UIButton.checkBoxStyleButton()
        btn.setTitleColor(.color(type: .text), for: .normal)
        btn.setTitle("  " + localizeStrings("Have read and agree") + " ", for: .normal)
        btn.addTarget(self, action: #selector(onClickAgreement), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 0)
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.titleLabel?.minimumScaleFactor = 0.1
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.numberOfLines = 1
        btn.titleLabel?.lineBreakMode = .byClipping
        btn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return btn
    }()
}
