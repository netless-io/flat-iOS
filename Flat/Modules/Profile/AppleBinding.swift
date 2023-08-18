//
//  AppleBinding.swift
//  Flat
//
//  Created by xuyunshi on 2023/08/18.
//  Copyright © 2021 agora.io. All rights reserved.
//

import AuthenticationServices
import UIKit

class AppleBinding: NSObject, ASAuthorizationControllerDelegate {
    private var handler: (Error?) -> Void
    
    init(handler: @escaping (Error?) -> Void) {
        self.handler = handler
    }
    
    func startBinding(sender: UIView) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = sender.window as? ASAuthorizationControllerPresentationContextProviding
        controller.performRequests()
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let token = credential.identityToken,
           let str = String(data: token, encoding: .utf8)
        {
            var name = credential.fullName?.givenName
            name?.append(credential.fullName?.familyName ?? "")
            ApiProvider.shared.request(fromApi: AppleBindingRequest(jwtToken: str, nickname: name)) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.handler(nil)
                case let .failure(error):
                    self.handler(error)
                }
            }
        } else {
            handler("decode auth error")
        }
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        handler(error.localizedDescription)
    }
}
