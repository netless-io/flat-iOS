//
//  String+regex.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/11.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

private let __firstpart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
private let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
private let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
private let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)

private let __passwordRegex = "(?=.*[a-zA-Z])(?=.*[0-9]).{8,}$"
private let __passwordPredicate = NSPredicate(format: "SELF MATCHES %@", __passwordRegex)

extension String {
    func isEmail() -> Bool {
        return __emailPredicate.evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        return __passwordPredicate.evaluate(with: self)
    }
}
