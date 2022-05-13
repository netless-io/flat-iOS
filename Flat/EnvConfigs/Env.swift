//
//  XCConfiguration.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

struct Env {
    enum Region: String {
        case CN
        case US
    }
    
    fileprivate func value<T>(for key: String) -> T {
        guard let value = Bundle.main.infoDictionary?[key] as? T else {
            fatalError("Invalid or missing Info.plist key: \(key)")
        }
        return value
    }
    
    var region: Region {
        Region(rawValue: value(for: "REGION")) ?? .US
    }
    
    var wechatAppId: String {
        value(for: "WECHAT_APP_ID") as String
    }
    
    var githubClientId: String {
        value(for: "GITHUB_CLIENT_ID") as String
    }
    
    var webBaseURL: String {
        "https://\(value(for: "FLAT_WEB_BASE_URL") as String)"
    }
    
    var baseURL: String {
        "https://\(value(for: "API_URL") as String)"
    }
    
    var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }
    
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    var ossAccessKeyId: String {
        Bundle.main.infoDictionary?["OSS_ACCESS_KEY_ID"] as? String ?? ""
    }
    
    var netlessAppId: String {
        Bundle.main.infoDictionary?["NETLESS_APP_ID"] as? String ?? ""
    }
    
    var agoraAppId: String {
        Bundle.main.infoDictionary?["AGORA_APP_ID"] as? String ?? ""
    }
}
