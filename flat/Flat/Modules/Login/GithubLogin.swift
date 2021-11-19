//
//  GithubLogin.swift
//  flat
//
//  Created by xuyunshi on 2021/10/13.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation
import UIKit
import SafariServices

class GithubLogin: LaunchItem {
    func shouldHandle(url: URL) -> Bool {
        guard url.absoluteString == "x-agora-flat-client://open",
                handler != nil else { return false }
        return true
    }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator) {
        guard let handler = handler else { return }
        ApiProvider.shared.request(fromApi: AuthProcessRequest(uuid: uuid), completionHandler: handler)
    }
    
    var afterLoginImplementation: ((LaunchCoordinator) -> Void)? { nil }
    
    let uuid: String = UUID().uuidString
    
    var handler: LoginHanlder?
    
    func startLogin(completionHandler: @escaping LoginHanlder) {
        ApiProvider.shared.request(fromApi: SetAuthUuidRequest(uuid: uuid)) { r in
            switch r {
            case .success:
                let controller = SFSafariViewController(url: self.githubLoginURL)
                controller.modalPresentationStyle = .pageSheet
                UIApplication.shared.topViewController?.present(controller, animated: true, completion: nil)
                self.handler = completionHandler
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    var githubLoginURL: URL {
        let env = Env()
        return URL(string: "https://github.com/login/oauth/authorize?client_id=\(env.githubClientId)&redirect_uri=\(env.baseURL)/v1/login/github/callback&state=\(uuid)")!
    }
}




