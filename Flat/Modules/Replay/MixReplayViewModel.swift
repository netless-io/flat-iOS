//
//  MixReplayViewModel.swift
//  Flat
//
//  Created by xuyunshi on 2022/11/3.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation
import RxSwift
import SyncPlayer
import Whiteboard

class MixReplayViewModel {
    struct PlayRecord {
        let player: SyncPlayer
        let rtcPlayer: AVPlayer? // RtcPlayer may be nil.
        let duration: TimeInterval
    }

    let recordDetail: RecordDetailInfo

    var currentIndex: Int?
    var whiteSDK: WhiteSDK!

    internal init(recordDetail: RecordDetailInfo) {
        self.recordDetail = recordDetail
    }

    func setupWhite(_ whiteboardView: WhiteBoardView, index: Int) -> Single<PlayRecord> {
        showLog = true

        currentIndex = index
        let config = WhiteSdkConfiguration(app: Env().netlessAppId)
        config.region =  recordDetail.region.toWhiteRegion()
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
        switch Theme.shared.style {
        case .light:
            windowParams.prefersColorScheme = .light
        case .dark:
            windowParams.prefersColorScheme = .dark
        case .auto:
            windowParams.prefersColorScheme = .auto
        }
        windowParams.containerSizeRatio = NSNumber(value: ClassRoomLayoutRatioConfig.whiteboardRatio)

        whitePlayerConfig.windowParams = windowParams

        let record = recordDetail.recordInfo[index]
        let beginTimeStamp = record.beginTime.timeIntervalSince1970
        let duration = record.endTime.timeIntervalSince(record.beginTime)
        whitePlayerConfig.beginTimestamp = NSNumber(value: beginTimeStamp)
        whitePlayerConfig.duration = NSNumber(value: duration)
        let whitePlayer = Observable<WhitePlayer>.create { [weak self] observer in
            guard let self else {
                observer.onError("self not exist")
                return Disposables.create()
            }
            self.whiteSDK.createReplayer(with: whitePlayerConfig, callbacks: nil) { _, player, error in
                if let error {
                    observer.onError(error)
                } else if let player {
                    observer.onNext(player)
                } else {
                    observer.onError("unknown player create error")
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
        
        let videoPlayer = Observable<AVPlayer?>.create { subscribe in
            let url = record.videoURL
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            let task = URLSession.shared.dataTask(with: request) { _, res, error in
                if let res = res as? HTTPURLResponse, res.statusCode == 200 {
                    subscribe.onNext(AVPlayer(url: url))
                    subscribe.onCompleted()
                    return
                }
                subscribe.onNext(nil)
                subscribe.onCompleted()
                return
            }
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
        
        let playRecord = Observable.zip(whitePlayer, videoPlayer)
            .map { white, av -> PlayRecord in
                let syncPlayer: SyncPlayer
                if let av {
                    syncPlayer = SyncPlayer(players: [av, white])
                } else {
                    syncPlayer = SyncPlayer(players: [white])
                }
                return .init(player: syncPlayer, rtcPlayer: av, duration: duration)
            }
            .asSingle()
        
        return playRecord
    }
}
