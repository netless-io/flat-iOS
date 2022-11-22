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
    let pStr = pretty(agreementTitle: localizeStrings("Privacy Policy"))
    let sStr = pretty(agreementTitle: localizeStrings("Service Agreement"))
    let str = localizeStrings("AgreementText")
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineSpacing = 2
    let attributedStr = NSMutableAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.color(type: .text), .paragraphStyle: paraStyle])
    attributedStr.add(link: privacyLink, forExistString: pStr)
    attributedStr.add(link: serviceLink, forExistString: sStr)
    return attributedStr
}

func agreementAttributedString1()-> NSAttributedString {
    let pStr = pretty(agreementTitle: localizeStrings("Privacy Policy"))
    let sStr = pretty(agreementTitle: localizeStrings("Service Agreement"))
    let str = localizeStrings("AgreementText1")
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.lineSpacing = 2
    let attributedStr = NSMutableAttributedString(string: str, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.color(type: .text), .paragraphStyle: paraStyle])
    attributedStr.add(link: privacyLink, forExistString: pStr)
    attributedStr.add(link: serviceLink, forExistString: sStr)
    return attributedStr
}

func pretty(agreementTitle: String)-> String {
    if LocaleManager.language == .Chinese { return "《\(agreementTitle)》" }
    return agreementTitle
}
