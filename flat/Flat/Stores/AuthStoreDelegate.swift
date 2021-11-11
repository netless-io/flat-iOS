//
//  AuthStoreDelegate.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol AuthStoreDelegate: AnyObject {
    func authStoreDidLoginSuccess(_ authStore: AuthStore, user: User)
    
    func authStoreDidLoginFail(_ authStore: AuthStore, error: Error)
    
    func authStoreDidLogout(_ authStore: AuthStore)
}
