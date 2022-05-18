//
//  Agreement.swift
//  Flat
//
//  Created by xuyunshi on 2022/5/18.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

let privacyLink = "https://flat.whiteboard.agora.io/privacy.html"
let serviceLink = "https://flat.whiteboard.agora.io/service.html"

func agreementAttributedString()-> NSAttributedString {
    let pStr = pretty(agreementTitle: NSLocalizedString("Privacy Policy", comment: ""))
    let sStr = pretty(agreementTitle: NSLocalizedString("Service Agreement", comment: ""))
    let str = NSLocalizedString("AgreementText", comment: "")
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineSpacing = 2
    let attributedStr = NSMutableAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.text, .paragraphStyle: paraStyle])
    attributedStr.add(link: privacyLink, forExistString: pStr)
    attributedStr.add(link: serviceLink, forExistString: sStr)
    return attributedStr
}

func agreementAttributedString1()-> NSAttributedString {
    let pStr = pretty(agreementTitle: NSLocalizedString("Privacy Policy", comment: ""))
    let sStr = pretty(agreementTitle: NSLocalizedString("Service Agreement", comment: ""))
    let str = NSLocalizedString("AgreementText1", comment: "")
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineSpacing = 2
    let attributedStr = NSMutableAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.text, .paragraphStyle: paraStyle])
    attributedStr.add(link: privacyLink, forExistString: pStr)
    attributedStr.add(link: serviceLink, forExistString: sStr)
    return attributedStr
}

func pretty(agreementTitle: String)-> String {
    if LocaleManager.language == .Chinese { return "《\(agreementTitle)》" }
    return agreementTitle
}
