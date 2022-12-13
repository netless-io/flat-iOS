//
//  JoinRoomLaunchItem.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/3.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxSwift

class JoinRoomLaunchItem: LaunchItem {
    var uuid: String!

    var disposeBag = RxSwift.DisposeBag()

    func shouldHandle(url: URL?) -> Bool {
        if let url {
            if url.scheme == "x-agora-flat-client",
               url.host == "joinRoom",
               let roomId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
               .queryItems?
               .first(where: { $0.name == "roomUUID" })?
               .value,
               roomId.isNotEmptyOrAllSpacing
            {
                uuid = roomId
                return true
            } else if let roomId = getUniversalLinkRoomUUID(url) {
                uuid = roomId
                UIApplication.shared.topViewController?.showAlertWith(message: roomId)
                return true
            }
        }
        return false
    }

    fileprivate func getUniversalLinkRoomUUID(_ url: URL) -> String? {
        if url.pathComponents.contains("join"),
           let roomUUID = url.pathComponents.last,
           roomUUID.isNotEmptyOrAllSpacing
        {
            return roomUUID
        }
        return nil
    }

    func shouldHandle(userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        if let roomId = getUniversalLinkRoomUUID(url) {
            uuid = roomId
            return true
        }
        return false
    }

    func immediateImplementation(withLaunchCoordinator _: LaunchCoordinator) {}

    func afterLoginSuccessImplementation(withLaunchCoordinator _: LaunchCoordinator, user: User) {
        guard let id = uuid else { return }
        let deviceStatusStore = UserDevicePreferredStatusStore(userUUID: user.userUUID)
        let micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        let cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        var mainVC: MainContainer
        if let vc = UIApplication.shared.topViewController?.presentingViewController,
           let svc = vc as? MainContainer
        {
            mainVC = svc
        } else if let svc = UIApplication.shared.topViewController?.mainContainer {
            mainVC = svc
        } else {
            return
        }
        if let existRoomVC = mainVC.concreteViewController.presentedViewController as? ClassRoomViewController,
           existRoomVC.viewModel.roomUUID == id
        {
            return
        }
        mainVC.concreteViewController.showActivityIndicator()

        RoomPlayInfo.fetchByJoinWith(uuid: id, periodicUUID: nil)
            .concatMap { info in
                RoomBasicInfo.fetchInfoBy(uuid: info.roomUUID, periodicUUID: nil).map { (info, $0) }
            }
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { playInfo, roomInfo in
                let deviceStatus = DeviceState(mic: micOn, camera: cameraOn)
                let vc = ClassroomFactory.getClassRoomViewController(withPlayInfo: playInfo,
                                                                     detailInfo: roomInfo,
                                                                     deviceStatus: deviceStatus)
                mainVC.concreteViewController.present(vc, animated: true, completion: nil)
                mainVC.concreteViewController.stopActivityIndicator()
            }, onFailure: { error in
                mainVC.concreteViewController.stopActivityIndicator()
                mainVC.concreteViewController.showAlertWith(message: error.localizedDescription)
            }, onDisposed: {})
            .disposed(by: disposeBag)
    }
}
