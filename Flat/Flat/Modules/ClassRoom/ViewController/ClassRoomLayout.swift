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
    
    enum WhiteboardLayoutStyle {
        case fixedWidth(CGFloat)
        case fixedHeight(CGFloat)
    }
    
    /// If direction is top, the margin is top and bottom; Or the margin is left and right for right
    let rtcMargin: CGFloat = 10
    /// If estimate rtc height less than minRtcHeight, it turn to .right
    fileprivate let minRtcHeight: CGFloat = 88
    let verticalRtcFixedHeight: CGFloat = 84
    let rtcRatio = ClassRoomLayoutRatioConfig.rtcItemRatio
    let rtcMinRatio: CGFloat = 0.1
    let rtcMaxRatio: CGFloat = 0.3
    let whiteboardRatio: CGFloat = CGFloat(ClassRoomLayoutRatioConfig.whiteboardRatio)
    
    func update(rtcHide: Bool, contentSize: CGSize) -> OutPut {
        print("ClassRoomLayout update from \(rtcHide), \(contentSize)")
        let value = resize(preferredStyle: .fixedWidth(contentSize.width), isRtcHide: rtcHide, contentSize: contentSize)
        print("ClassRoomLayout \(value.0), \(value.1)")
        return value.0
    }
    
    private func resize(preferredStyle: WhiteboardLayoutStyle, isRtcHide: Bool, contentSize: CGSize) -> (OutPut, WhiteboardLayoutStyle) {
        switch preferredStyle {
        case .fixedWidth(let width):
            let estimateRtcHeight: CGFloat = isRtcHide ? 0 : (rtcMinRatio * contentSize.height + (2 * rtcMargin))
            let rtcDirection: RtcDirection = estimateRtcHeight == 0 ? .top : (estimateRtcHeight < minRtcHeight ? .right : .top)
            switch rtcDirection {
            case .top:
                let estimateWhiteHeight = width * whiteboardRatio
                let estimateHeight = estimateWhiteHeight + estimateRtcHeight
                if estimateHeight > contentSize.height {
                    return resize(preferredStyle: .fixedHeight(contentSize.height), isRtcHide: isRtcHide, contentSize: contentSize)
                } else {
                    let heightDelta = contentSize.height - estimateHeight
                    let realRtcHeight = min((isRtcHide ? 0 : heightDelta + estimateRtcHeight), rtcMaxRatio * contentSize.height)
                    let extraHeight = contentSize.height - realRtcHeight - estimateWhiteHeight
                    let topMargin: CGFloat
                    let bottomMargin: CGFloat
                    if isRtcHide {
                        topMargin = extraHeight / 2
                        bottomMargin = extraHeight / 2
                    } else {
                        topMargin = 0
                        bottomMargin = extraHeight
                    }
                    let output = OutPut(rtcSize: .init(width: contentSize.width, height: realRtcHeight),
                                        rtcDirection: rtcDirection,
                                        whiteboardSize: .init(width: width, height: estimateHeight),
                                        inset: .init(top: topMargin, left: 0, bottom: bottomMargin, right: 0))
                    return (output, preferredStyle)
                }
            case .right:
                var estimateWhiteHeight = contentSize.height
                var estimateWhiteWidth = estimateWhiteHeight / whiteboardRatio
                let estimateRtcWidth = verticalRtcFixedHeight / rtcRatio + (2 * rtcMargin)
                if estimateWhiteWidth < contentSize.width, contentSize.width - estimateWhiteWidth >= estimateRtcWidth {
                    let rtcWidth = contentSize.width - estimateWhiteWidth
                    let output = OutPut(rtcSize: .init(width: rtcWidth, height: contentSize.height),
                                        rtcDirection: rtcDirection,
                                        whiteboardSize: .init(width: estimateWhiteWidth, height: estimateWhiteHeight),
                                        inset: .init(top: 0, left: 0, bottom: 0, right: 0))
                    return (output, preferredStyle)
                }
                
                estimateWhiteWidth = contentSize.width - estimateRtcWidth
                estimateWhiteHeight = estimateWhiteWidth * whiteboardRatio
                if estimateWhiteHeight > contentSize.height {
                    return resize(preferredStyle: .fixedHeight(contentSize.height), isRtcHide: isRtcHide, contentSize: contentSize)
                } else {
                    let deltaHeight = contentSize.height - estimateWhiteHeight
                    let tbMargin = deltaHeight / 2
                    let output = OutPut(rtcSize: .init(width: estimateRtcWidth, height: estimateWhiteHeight),
                                        rtcDirection: rtcDirection,
                                        whiteboardSize: .init(width: estimateWhiteWidth, height: estimateWhiteHeight),
                                        inset: .init(top: tbMargin, left: 0, bottom: tbMargin, right: 0))
                    return (output, preferredStyle)
                }
            }
        case .fixedHeight(let height):
            let estimateRtcHeight: CGFloat = isRtcHide ? 0 : rtcMinRatio * contentSize.height + (2 * rtcMargin)
            let rtcDirection: RtcDirection = estimateRtcHeight == 0 ? .top : (estimateRtcHeight < minRtcHeight ? .right : .top)
            switch rtcDirection {
            case .top:
                let whiteHeight = height - estimateRtcHeight
                let whiteWidth = whiteHeight / whiteboardRatio
                if whiteWidth > contentSize.width {
                    return resize(preferredStyle: .fixedWidth(contentSize.width), isRtcHide: isRtcHide, contentSize: contentSize)
                } else {
                    let deltaWidth = contentSize.width - whiteWidth
                    let horizontalMargin = deltaWidth / 2
                    let output = OutPut(rtcSize: .init(width: whiteWidth, height: estimateRtcHeight),
                                        rtcDirection: rtcDirection,
                                        whiteboardSize: .init(width: whiteWidth, height: whiteHeight),
                                        inset: .init(top: 0, left: horizontalMargin, bottom: 0, right: horizontalMargin))
                    return (output, preferredStyle)
                }
            case .right:
                let whiteHeight = height
                let whiteWidth = height / whiteboardRatio
                let estimateRtcWidth = verticalRtcFixedHeight / rtcRatio + (2 * rtcMargin)
                let width = estimateRtcWidth + whiteWidth
                if width > contentSize.width {
                    return resize(preferredStyle: .fixedWidth(contentSize.width), isRtcHide: isRtcHide, contentSize: contentSize)
                } else {
                    let deltaWidth = contentSize.width - width
                    let lrMargin = deltaWidth / 2
                    let output = OutPut(rtcSize: .init(width: estimateRtcWidth, height: height),
                                        rtcDirection: rtcDirection,
                                        whiteboardSize: .init(width: whiteWidth, height: whiteHeight),
                                        inset: .init(top: 0, left: lrMargin, bottom: 0, right: lrMargin))
                    return (output, preferredStyle)
                }
            }
        }
    }
}
