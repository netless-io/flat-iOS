//
//  ClassroomViewController+rtcHideDragging.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/7.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

extension ClassRoomViewController {
    @objc func onRtcDraggingGesture(_ panGesture: UIPanGestureRecognizer) {
        func beginDragging() {
            Self.cancelPreviousPerformRequests(withTarget: self, selector: #selector(cancelDraggingHint), object: nil)
            rtcDraggingHandlerView.alpha = 1
            rtcIndicatorDraggingPreviousTranslation = currentTranslation
            draggingTranslation = 0
            draggingStartRtcLength = min(rtcListViewController.view.bounds.height, rtcListViewController.view.bounds.width)
        }
        func finishDragging() {
            perform(#selector(cancelDraggingHint), with: nil, afterDelay: 1.0)

            let isPhone = UIDevice.current.userInterfaceIdiom == .phone
            let lowerBound = classroomRtcComactLength
            let upperBound = isPhone ? classroomRtcMinWidth : classroomRtcMinHeight
            // Trigger from settingvc to sync hide info.
            let isVideoAreaOn = settingVC.videoAreaOn.value
            if isVideoAreaOn {
                if draggingTranslation <= lowerBound {
                    settingVC.videoAreaPublish.accept(()) // Show hide rtc style.
                } else {
                    performRtc(hide: false)
                }
            } else {
                if draggingTranslation > upperBound {
                    settingVC.videoAreaPublish.accept(()) // Show rtc style.
                } else {
                    performRtc(hide: true)
                }
            }
        }
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let currentTranslation: CGFloat = isPhone ?
            -panGesture.translation(in: rtcDraggingHandlerView).x :
            panGesture.translation(in: rtcDraggingHandlerView).y
        switch panGesture.state {
        case .began:
            beginDragging()
        case .changed:
            draggingTranslation += (currentTranslation - rtcIndicatorDraggingPreviousTranslation)
            let adjustedLength: CGFloat
            if isPhone {
                adjustedLength = min(
                    max(classroomRtcComactLength, draggingStartRtcLength + draggingTranslation),
                    classroomRtcMaxWidth
                )
            } else {
                adjustedLength = min(
                    max(classroomRtcComactLength, draggingStartRtcLength + draggingTranslation),
                    classroomRtcMaxHeight
                )
            }
            updateRtcViewConstraint(length: adjustedLength)

            let showCompactLowerBound = classroomRtcComactLength + 30
            let alphaTransitionLength = CGFloat(20)
            
            // NOTE:
            // `alphaTransitionLength` + `showCompactLowerBound` should less than `targetLength`
            if adjustedLength <= showCompactLowerBound {
                rtcListViewController.mainScrollView.alpha = 0
                classroomStatusBar.onStageStatusButton.alpha = 1
            } else if adjustedLength <= showCompactLowerBound + alphaTransitionLength {
                rtcListViewController.mainScrollView.alpha = (adjustedLength - showCompactLowerBound) / alphaTransitionLength
                classroomStatusBar.onStageStatusButton.alpha = 1 - rtcListViewController.mainScrollView.alpha
            } else {
                rtcListViewController.mainScrollView.alpha = 1
                classroomStatusBar.onStageStatusButton.alpha = 0
            }

            rtcIndicatorDraggingPreviousTranslation = currentTranslation
        case .cancelled:
            finishDragging()
        case .ended:
            // Add velocity.
            draggingTranslation += isPhone ?
                -panGesture.velocity(in: rtcDraggingHandlerView).x :
                panGesture.velocity(in: rtcDraggingHandlerView).y
            finishDragging()
        default:
            return
        }
    }

    func setupRtcDragging() {
        guard let rtcView = rtcListViewController.view else { return }
        view.addSubview(rtcDraggingHandlerView)
        let isiPhone = UIDevice.current.userInterfaceIdiom == .phone

        let draggingHotSize = isiPhone ? CGSize(width: 32, height: 144) : CGSize(width: 144, height: 32)
        let indicatorSize = isiPhone ? CGSize(width: 2, height: 88) : CGSize(width: 88, height: 4)
        let indicatorMargin = isiPhone ? CGFloat(3) : CGFloat(8)
        UIGraphicsBeginImageContext(draggingHotSize)
        UIColor.lightGray.setFill()
        let imageRectPath: CGRect
        if isiPhone {
            imageRectPath = .init(origin: .init(x: draggingHotSize.width - indicatorMargin - indicatorSize.width, y: (draggingHotSize.height - indicatorSize.height) / 2),
                                  size: indicatorSize)
        } else {
            imageRectPath = .init(origin: .init(x: (draggingHotSize.width - indicatorSize.width) / 2, y: indicatorMargin),
                                  size: indicatorSize)
        }
        let indicatorBezierPath = UIBezierPath(
            roundedRect: imageRectPath,
            cornerRadius: isiPhone ? indicatorSize.width / 2 : indicatorSize.height / 2
        )
        indicatorBezierPath.fill()
        let indicatorImage = UIGraphicsGetImageFromCurrentImageContext()
        rtcDraggingHandlerView.image = indicatorImage

        if isiPhone {
            rtcDraggingHandlerView.snp.makeConstraints { make in
                make.centerY.equalTo(rtcView)
                make.right.equalTo(rtcView.snp.left)
                make.size.equalTo(draggingHotSize)
            }
        } else {
            rtcDraggingHandlerView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(rtcView.snp.bottom)
                make.size.equalTo(draggingHotSize)
            }
        }

        let rtcDraggingGesture = UIPanGestureRecognizer(target: self, action: #selector(onRtcDraggingGesture))
        rtcDraggingHandlerView.addGestureRecognizer(rtcDraggingGesture)
    }

    @objc
    func cancelDraggingHint() {
        UIView.animate(withDuration: 0.3) {
            self.rtcDraggingHandlerView.alpha = 0.3
        }
    }
}
