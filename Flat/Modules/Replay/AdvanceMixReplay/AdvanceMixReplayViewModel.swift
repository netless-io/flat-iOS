//
//  AdvanceMixReplayViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import Whiteboard
import SyncPlayer
import RxSwift

class AdvanceMixReplayViewModel {
    struct PlayRecord {
        let player: SyncPlayer
        let rtcPlayer: AVPlayer
        let duration: TimeInterval
    }
    
    let roomInfo: RoomBasicInfo
    let recordDetail: RecordDetailInfo
    
    var currentIndex: Int? = nil
    var whiteSDK: WhiteSDK!
    
    internal init(roomInfo: RoomBasicInfo, recordDetail: RecordDetailInfo) {
        self.roomInfo = roomInfo
        self.recordDetail = recordDetail
    }
    
    func setupWhite(_ whiteboardView: WhiteBoardView, index: Int) -> Single<PlayRecord> {
        showLog = true
        
        currentIndex = index
        let config = WhiteSdkConfiguration(app: Env().netlessAppId)
        config.region = .CN
        config.userCursor = true
        config.useMultiViews = true
        config.log = false
        
        whiteSDK = WhiteSDK(whiteBoardView: whiteboardView,
                            config: config,
                            commonCallbackDelegate: nil)
        
        let whitePlayerConfig = WhitePlayerConfig(room: recordDetail.whiteboardRoomUUID,
                                                  roomToken: recordDetail.whiteboardRoomToken)
        let windowParams = WhiteWindowParams()
        windowParams.scrollVerticalOnly = true
        windowParams.stageStyle = "box-shadow: 0 0 0"
        windowParams.prefersColorScheme = .auto
        windowParams.containerSizeRatio = NSNumber(value: 1 / ClassRoomLayoutRatioConfig.whiteboardRatio)
        
        whitePlayerConfig.windowParams = windowParams
        
        let record = recordDetail.recordInfo[index]
        let beginTimeStamp = record.beginTime.timeIntervalSince1970
        let duration = record.endTime.timeIntervalSince(record.beginTime)
        whitePlayerConfig.beginTimestamp = NSNumber(value: beginTimeStamp)
        whitePlayerConfig.duration = NSNumber(value: duration)
        let whitePlayer = Observable<WhitePlayer>.create { [weak self] observer in
            guard let self = self else {
                observer.onError("self not exist")
                return Disposables.create()
            }
            self.whiteSDK.createReplayer(with: whitePlayerConfig, callbacks: nil) { success, player, error in
                if let error = error {
                    observer.onError(error)
                } else if let player = player {
                    observer.onNext(player)
                } else {
                    observer.onError("unknown player create error")
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
        
        return whitePlayer
            .map { whitePlayer -> PlayRecord in
                let rtcPlayer = AVPlayer(url: record.videoURL)
                let syncPlayer = SyncPlayer(players: [rtcPlayer, whitePlayer])
                return .init(player: syncPlayer, rtcPlayer: rtcPlayer, duration: duration)
            }
            .asSingle()
    }
}
