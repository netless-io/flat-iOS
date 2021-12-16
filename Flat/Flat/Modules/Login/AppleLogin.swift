//
//  AppleLogin.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import AuthenticationServices

@available(iOS 13.0, *)
class AppleLogin: NSObject, ASAuthorizationControllerDelegate {
    var handler: LoginHandler?
    
    func startLogin(launchCoordinator: LaunchCoordinator, loginHandler: LoginHandler?) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = globalLaunchCoordinator?.window as? ASAuthorizationControllerPresentationContextProviding
        controller.performRequests()
        self.handler = loginHandler
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let token = credential.identityToken,
           let str = String(data: token, encoding: .utf8)
        {
            var name = credential.fullName?.givenName
            name?.append(credential.fullName?.familyName ?? "")
            ApiProvider.shared.request(fromApi: AppleLoginRequest(jwtToken: str, nickname: name)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    AuthStore.shared.processLoginSuccessUserInfo(user)
                    self.handler?(.success(user))
                    self.handler = nil
                case .failure(let error):
                    self.handler?(.failure(error))
                    self.handler = nil
                }
            }
        } else {
            handler?(.failure(.message(message: "decode auth error")))
            handler = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handler?(.failure(.message(message: error.localizedDescription)))
        handler = nil
    }
}
