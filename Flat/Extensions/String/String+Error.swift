//
//  String+Error.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { self }
}
