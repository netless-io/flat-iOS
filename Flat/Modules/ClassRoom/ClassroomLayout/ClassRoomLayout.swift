//
//  ClassRoomLayout.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class ClassRoomLayout {
    struct OutPut {
        let rtcSize: CGSize
        let rtcDirection: RtcDirection
        let whiteboardSize: CGSize
        let inset: UIEdgeInsets
    }

    enum RtcDirection {
        case top
        case right
    }

    struct Input {
        let rawContentSize: CGSize
        let hideRtc: Bool
        let preferredStyle: RtcDirection
        var actualContentSize: CGSize?

        mutating func update(actualContentSize: CGSize) {
            self.actualContentSize = actualContentSize
        }
    }
    
    /// If direction is top, the margin is top and bottom; Or the margin is left and right for right
    let rtcMargin: CGFloat = 0
//    /// If estimate rtc height less than minRtcHeight, it turn to .right
    private var minRtcHeight: CGFloat = 108
    private var maxRtcHeight: CGFloat = 144
    let rtcRatio = ClassRoomLayoutRatioConfig.rtcItemRatio
    let whiteboardRatio: CGFloat = .init(ClassRoomLayoutRatioConfig.whiteboardRatio)
    let reduceLevel: CGFloat = 1
    
    var layoutCache: [Input: OutPut] = [:]
    
    func getlayout(from: Input) -> OutPut {
        if let output = layoutCache[from] {
            return output
        }
        let width = (from.actualContentSize ?? from.rawContentSize).width
        let height = (from.actualContentSize ?? from.rawContentSize).height
        switch from.preferredStyle {
        case .top:
            let estimateWhiteHeight = (width * whiteboardRatio).rounded()
            if estimateWhiteHeight > height {
                var newConfig = from
                newConfig.update(actualContentSize: .init(width: width - reduceLevel, height: height))
                return getlayout(from: newConfig)
            } else {
                let rtcHeight = height - estimateWhiteHeight
                let rtcContentHeight = rtcHeight - (2 * rtcMargin)
                if rtcContentHeight < minRtcHeight {
                    var newConfig = from
                    newConfig.update(actualContentSize: .init(width: width - reduceLevel, height: height))
                    return getlayout(from: newConfig)
                }
                if rtcContentHeight > maxRtcHeight {
                    var newConfig = from
                    newConfig.update(actualContentSize: .init(width: width, height: height - reduceLevel))
                    return getlayout(from: newConfig)
                }
                let xInset = ((from.rawContentSize.height - height) / 2).rounded()
                let yInset = ((from.rawContentSize.width - width) / 2).rounded()
                let output = OutPut(rtcSize: .init(width: width, height: rtcHeight),
                                   rtcDirection: .top,
                                   whiteboardSize: .init(width: width, height: estimateWhiteHeight),
                                   inset: .init(top: xInset, left: yInset, bottom: 0, right: 0))
                layoutCache[from] = output
                return output
            }
        case .right:
            let estimateWhiteHeight = height
            let estimateWhiteWidth = (estimateWhiteHeight / whiteboardRatio).rounded()
            let estimateRTCWidth = width - estimateWhiteWidth
            let estimateRTCContentWidth = estimateRTCWidth - (2 * rtcMargin)
            let estimateRTCContentHeight = estimateRTCContentWidth * rtcRatio
            if estimateRTCContentHeight < minRtcHeight {
                var newConfig = from
                newConfig.update(actualContentSize: .init(width: width, height: height - reduceLevel))
                return getlayout(from: newConfig)
            }
            if estimateRTCContentHeight > maxRtcHeight {
                var newConfig = from
                newConfig.update(actualContentSize: .init(width: width - reduceLevel, height: height))
                return getlayout(from: newConfig)
            }
            let xInset = ((from.rawContentSize.height - height) / 2).rounded()
            let yInset = ((from.rawContentSize.width - width) / 2).rounded()
            let output = OutPut(rtcSize: .init(width: estimateRTCWidth, height: height),
                         rtcDirection: .right,
                         whiteboardSize: .init(width: estimateWhiteWidth, height: estimateWhiteHeight),
                         inset: .init(top: xInset, left: yInset, bottom: 0, right: 0))
            layoutCache[from] = output
            return output
        }
    }

}

extension ClassRoomLayout.Input: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawContentSize.width)
        hasher.combine(rawContentSize.height)
        hasher.combine(hideRtc)
        hasher.combine(preferredStyle)
    }
}
