//
//  ClassroomSceneDelegate.swift
//  Flat
//
//  Created by xuyunshi on 2023/1/10.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxSwift

class ClassroomSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene
//              let id = session.userInfo?["roomUUID"] as? String
        else { return }
//        let periodicUUID = session.userInfo?["periodicUUID"] as? String
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.backgroundColor = .color(type: .background)
        window?.makeKeyAndVisible()
//        joinRoom(uuid: id, periodicUUID: periodicUUID, window: window)
    }
}
