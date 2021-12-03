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
    
    var disposeBag = DisposeBag()
    
    func shouldHandle(url: URL?) -> Bool {
        guard let url = url,
                url.scheme == "x-agora-flat-client",
                url.host == "joinRoom" else {
                    return false
                }
        guard let item = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "roomUUID"}),
              let id = item.value,
              !id.isNotEmptyOrAllSpacing
        else { return false }
        self.uuid = id
        return true
    }
    
    func shouldHandle(userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else { return false }
        guard url.pathComponents.contains("join"),
                let roomUUID = url.pathComponents.last else { return false }
        self.uuid = roomUUID
        return true
    }
    
    func immediateImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator) {
        return
    }
    
    func afterLoginSuccessImplementation(withLaunchCoordinator launchCoordinator: LaunchCoordinator, user: User) {
        guard let id = uuid else { return }
        let deviceStatusStore = UserDevicePreferredStatusStore(userUUID: user.userUUID)
        let micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        let cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        let splitVC: MainSplitViewController
        if let vc = UIApplication.shared.topViewController?.presentingViewController,
           let svc = vc as? MainSplitViewController {
            splitVC = svc
        } else if let svc = UIApplication.shared.topViewController?.splitViewController as? MainSplitViewController {
            splitVC = svc
        } else if let svc = UIApplication.shared.topViewController as? MainSplitViewController {
            splitVC = svc
        } else {
            return
        }
        if let existRoomVC = splitVC.presentedViewController as? ClassRoomViewController,
           existRoomVC.viewModel.state.roomUUID == id {
            return
        }
        splitVC.showActivityIndicator()
        Observable.zip(RoomPlayInfo.fetchByJoinWith(uuid: id), RoomInfo.fetchInfoBy(uuid: id))
            .asSingle()
            .observe(on: MainScheduler.instance)
            .subscribe(with: splitVC, onSuccess: { weakSplitVC, tuple in
                let playInfo = tuple.0
                let roomInfo = tuple.1
                let deviceStatus = ClassRoomFactory.DeviceStatus(mic: micOn, camera: cameraOn)
                let vc = ClassRoomFactory.getClassRoomViewController(withPlayinfo: playInfo,
                                                                     detailInfo: roomInfo,
                                                                     deviceStatus: deviceStatus)
                
                let detailVC = RoomDetailViewControllerFactory.getRoomDetail(withInfo: roomInfo, roomUUID: playInfo.roomUUID)
                weakSplitVC.present(vc, animated: true, completion: nil)
                weakSplitVC.showDetailViewController(detailVC, sender: nil)
                weakSplitVC.stopActivityIndicator()
            }, onFailure: { weakSplitVC, error in
                weakSplitVC.stopActivityIndicator()
                weakSplitVC.showAlertWith(message: error.localizedDescription)
            }, onDisposed: { _ in
                return
            })
            .disposed(by: disposeBag)
    }
}
