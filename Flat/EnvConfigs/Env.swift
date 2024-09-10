//
//  XCConfiguration.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum LoginType: String, CaseIterable {
    case email
    case phone
    case github
    case apple
    case wechat
    case google
}

struct Env {
    struct ServerGroupItem: Decodable {
        fileprivate let apiURL: String
        let classroomInviteCode: Int
        let classroomUUIDPrefix: String
        var baseURL: String {
            "https://\(apiURL)"
        }
    }

    enum Region: String {
        case CN
        case US
    }

    func value<T>(for key: String) -> T {
        guard let value = Bundle.main.infoDictionary?[key] as? T else {
            fatalError("Invalid or missing Info.plist key: \(key)")
        }
        return value
    }

    var disabledLoginTypes: [LoginType] {
        (value(for: "DISABLE_LOGIN_TYPES") as String).split(separator: ",").compactMap { LoginType(rawValue: String($0)) }
    }

    var preferPhoneAccount: Bool {
        (value(for: "PREFER_PHONE_ACCOUNT") as String) == "1"
    }

    var forceBindPhone: Bool {
        (value(for: "FORCE_BIND_PHONE") as String) == "1"
    }

    var region: Region {
        Region(rawValue: value(for: "REGION")) ?? .US
    }

    var weChatAppId: String {
        value(for: "WECHAT_APP_ID") as String
    }

    var githubClientId: String {
        value(for: "GITHUB_CLIENT_ID") as String
    }

    var googleClientId: String {
        value(for: "GOOGLE_CLIENT_ID") as String
    }
    
    var appUpdateCheckURL: URL {
        .init(string: "https://" + (value(for: "APP_UPDATE_SOURCE") as String))!
    }
    
    var useCnSpecialAgreement: Bool {
        value(for: "CN_SPECIAL_AGREEMENT") as String == "1"
    }

    var serviceURL: URL? {
        .init(string: "https://" + (value(for: "SERVICE_URL") as String))
    }
    
    var privacyURL: URL? {
        .init(string: "https://" + (value(for: "PRIVACY_URL") as String))
    }
    
    var webBaseURL: String {
        "https://\(value(for: "FLAT_WEB_BASE_URL") as String)"
    }

    var baseURL: String {
        #if DEBUG
        let url = value(for: "API_URL") as String
        if url == "localhost" {
            return "http://\(url)"
        }
        #endif
        return "https://\(value(for: "API_URL") as String)"
    }

    var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    var servers: [ServerGroupItem] {
        do {
            let str = value(for: "SERVER_GROUP") as String
            if let data = str.data(using: .utf8) {
                let items = try JSONDecoder().decode([ServerGroupItem].self, from: data)
                return items
            }
        } catch {
            // Prevent it by unit test. So do nothing.
        }
        return []
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

    var slsProject: String {
        Bundle.main.infoDictionary?["SLS_PROJECT"] as? String ?? ""
    }

    var slsEndpoint: String {
        "https://" + (Bundle.main.infoDictionary?["SLS_ENDPOINT"] as? String ?? "")
    }

    var slsSk: String {
        Bundle.main.infoDictionary?["SLS_SK"] as? String ?? ""
    }

    var slsAk: String {
        Bundle.main.infoDictionary?["SLS_AK"] as? String ?? ""
    }
    
    var joinEarly: TimeInterval {
        let stored = UserDefaults.standard.value(forKey: "joinEarly") as? TimeInterval
        return stored ?? (5 * 60)
    }
    
    func updateJoinEarly(_ newValue: TimeInterval) {
        UserDefaults.standard.setValue(newValue, forKey: "joinEarly")
    }
}

private let googleAuthBaseUrl = "https://accounts.google.com/o/oauth2/v2/auth"
private let githubAuthBaseUrl = "https://github.com/login/oauth/authorize"
extension Env {
    func githubBindingURLWith(authUUID uuid: String) -> URL {
        let redirectUri = baseURL + "/v1/login/github/callback/binding"
        let queryString = "?client_id=\(githubClientId)&redirect_uri=\(redirectUri)&state=\(uuid)"
        let urlString = githubAuthBaseUrl + queryString
        return URL(string: urlString)!
    }

    func githubLoginURLWith(authUUID uuid: String) -> URL {
        let redirectUri = baseURL + "/v1/login/github/callback"
        let queryString = "?client_id=\(githubClientId)&redirect_uri=\(redirectUri)&state=\(uuid)"
        let urlString = githubAuthBaseUrl + queryString
        return URL(string: urlString)!
    }

    func googleBindingURLWith(authUUID uuid: String) -> URL {
        let redirectUrl = baseURL + "/v1/user/binding/platform/google"
        let scope = ["openid", "https://www.googleapis.com/auth/userinfo.profile"].joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let queryString = "?response_type=code&access_type=online&scope=\(scope)&client_id=\(googleClientId)&redirect_uri=\(redirectUrl)&state=\(uuid)"
        let urlString = googleAuthBaseUrl + queryString
        return URL(string: urlString)!
    }

    func googleLoginURLWith(authUUID uuid: String) -> URL {
        let redirectUrl = baseURL + "/v1/login/google/callback"
        let scope = ["openid", "https://www.googleapis.com/auth/userinfo.profile"].joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let queryString = "?response_type=code&access_type=online&scope=\(scope)&client_id=\(googleClientId)&redirect_uri=\(redirectUrl)&state=\(uuid)"
        let urlString = googleAuthBaseUrl + queryString
        return URL(string: urlString)!
    }
}

extension Env {
    var containsSlsInfo: Bool {
        !slsSk.isEmpty && !slsAk.isEmpty && !slsEndpoint.isEmpty && !slsProject.isEmpty
    }
}

extension Env {
    func customBaseUrlFor(roomUUID: String) -> String? {
        let isAllNumer = roomUUID.allSatisfy(\.isNumber)
        if isAllNumer, roomUUID.count == 10 {
            return servers.first(where: { $0.classroomUUIDPrefix == "CN-"})?.baseURL // Old invite code. Using CN.
        }
        for server in servers {
            if isAllNumer {
                if roomUUID.hasPrefix(server.classroomInviteCode.description) {
                    return server.baseURL
                }
            }
            if roomUUID.hasPrefix(server.classroomUUIDPrefix) {
                return server.baseURL
            }
        }
        return nil
    }
    
    func isCrossRegion(roomUUID: String) -> Bool {
        if let url = customBaseUrlFor(roomUUID: roomUUID) {
            return url != baseURL
        }
        return false
    }
}
