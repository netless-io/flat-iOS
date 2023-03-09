//
//  RtcViewController+Dragger.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/3.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

extension RtcViewController {
    func updateAnimate(for view: RtcItemContentView,
                       forwardsView: UIView,
                       forwardsFrame: CGRect) {
        let animationView = view
        let canvasView = draggingCanvasProvider.getDraggingView()
        guard let startFrame = animationView.superview?.convert(animationView.frame, to: canvasView) else { return }
        if animationView.superview != canvasView {
            canvasView.addSubview(animationView)
        }
        animationView.frame = startFrame
        let forwardsFrameInCanvas = forwardsView.convert(forwardsFrame, to: canvasView)
        
        let isSmallUpdate = forwardsFrameInCanvas.isChangeLessThen(1, from: startFrame)
        if isSmallUpdate { // Ignore smiliar frame animation.
            if animationView.superview != forwardsView {
                forwardsView.addSubview(animationView)
            }
            return
        }
        let isAnimationSmallUpdate = animationView.animationToFrame.isChangeLessThen(1, from: forwardsFrame)
        if isAnimationSmallUpdate {
            return
        }

        let fromCenter = startFrame.origin.applying(.init(translationX: startFrame.width / 2, y: startFrame.height / 2))
        let toCenter = forwardsFrameInCanvas.origin.applying(.init(translationX: forwardsFrameInCanvas.width / 2, y: forwardsFrameInCanvas.height / 2))
        animationView.animationToFrame = forwardsFrame
        animationView.startDragging(needSnapShot: true) // To avoid rtc size wrong
        animationView.animation(x: toCenter.x - fromCenter.x,
                                y: toCenter.y - fromCenter.y,
                                xScale: forwardsFrameInCanvas.width / startFrame.width,
                                yScale: forwardsFrameInCanvas.height / startFrame.height,
                                animationDuration: 0.35) { c in
            c.endDragging(needSnapShot: true)
            if c.superview != forwardsView {
                forwardsView.addSubview(c)
            }
            c.frame = forwardsFrame
            c.animationToFrame = .zero
        }
    }
    
    func expand(view: RtcVideoItemView, userIndex: Int, totalCount: Int) {
        let forwardsFrame = draggingCanvasProvider.getDraggingLayoutFor(index: userIndex, totalCount: totalCount)
        updateAnimate(for: view.contentView, forwardsView: draggingCanvasProvider.getDraggingView(), forwardsFrame: forwardsFrame)
    }
    
    func move(contentView: RtcItemContentView, toScaledRect rect: CGRect) {
        let canvasView = draggingCanvasProvider.getDraggingView()
        let canvasBounds = canvasView.bounds
        let forwardsFrame = CGRect(x: rect.origin.x * canvasBounds.width,
                                   y: rect.origin.y * canvasBounds.height,
                                   width: rect.width * canvasBounds.width,
                                   height: rect.height * canvasBounds.height)
        updateAnimate(for: contentView, forwardsView: canvasView, forwardsFrame: forwardsFrame)
    }
    
    // Minimal to top
    func minimal(view: RtcVideoItemView) {
        updateAnimate(for: view.contentView, forwardsView: view, forwardsFrame: .init(origin: .zero, size: rtcMinimalSize))
    }
    
    
    // MARK: - Pinch
    @objc func onPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let targetView = gesture.view as? RtcItemContentView else { return }
        let minWidth = draggingCanvasProvider.getDraggingView().bounds.width * minDraggingScaleOfCanvas
        let minScale = minWidth / targetView.bounds.width
        switch gesture.state {
        case .changed:
            let maxScale = draggingCanvasProvider.getDraggingLayoutFor(index: 0, totalCount: 1).width / targetView.bounds.width
            let scale = min(max(minScale, gesture.scale), maxScale)
            targetView.transform = .init(scaleX: scale, y: scale)
        case .ended:
            let maxScale = draggingCanvasProvider.getDraggingLayoutFor(index: 0, totalCount: 1).width / targetView.bounds.width
            let scale = min(max(minScale, gesture.scale), maxScale)
            let originSize = targetView.frame.size
            let size = targetView.frame.size.applying(.init(scaleX: scale, y: scale))
            targetView.frame = .init(origin: .init(x: targetView.frame.origin.x - originSize.width * (scale - 1) / 2,
                                                   y: targetView.frame.origin.y - originSize.height * (scale - 1) / 2),
                                     size: size)
            targetView.transform = .identity
        default:
            targetView.transform = .identity
        }
    }
    
    // MARK: - Drag position utilty
    
    func isContentView(_ contentView: UIView, totalInScrollView scrollView: UIScrollView) -> Bool {
        let bottomLeft = contentView.convert(CGPoint(x: 0, y: contentView.bounds.size.height), to: scrollView)
        switch direction {
        case .top:
            return bottomLeft.y < scrollView.bounds.height
        case .right:
            return bottomLeft.x > 0.1 // Using 0.1 because the value may be something like this 1.1368683772161603e-13
        }
    }
    
    func isContentView(_ contentView: UIView, partIn scrollView: UIScrollView) -> Bool {
        let bottomRight = contentView.convert(CGPoint(x: contentView.bounds.width, y: 0), to: scrollView)
        switch direction {
        case .top:
            return bottomRight.y < scrollView.bounds.height
        case .right:
            return bottomRight.x > 0.1 // Using 0.1 because the value may be something like this 1.1368683772161603e-13
        }
    }
    
    func isContentView(_ contentView: UIView, coverOverHalf scrollView: UIScrollView) -> Bool {
        let bottomRight = contentView.convert(CGPoint(x: contentView.bounds.width, y: 0), to: scrollView)
        switch direction {
        case .top:
            return bottomRight.y < scrollView.bounds.height / 2
        case .right:
            return bottomRight.x > scrollView.bounds.width / 2
        }
    }
    
    
    // MARK: - Dragging hint
    
    func startTargetViewHint(withAnimationView view: UIView) {
        Self.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(_delayedHint(withAnimationView:)), with: view, afterDelay: 0.0167, inModes: [.common])
    }
    
    @objc func _delayedHint(withAnimationView view: UIView) {
        if let draggingPossibleTargetView {
            switch draggingPossibleTargetView {
            case .grid:
                draggingCanvasProvider.startHint()
                view.superview?.bringSubviewToFront(view) // Hint bring border view to front. Then bring dragging to front again.
            case .minimal(let v):
                v.layer.borderColor = UIColor.color(type: .primary).cgColor
                v.layer.borderWidth = 3
            }
        }
    }

    func stopTargetViewHint() {
        Self.cancelPreviousPerformRequests(withTarget: self)
        if let draggingPossibleTargetView {
            switch draggingPossibleTargetView {
            case .grid: draggingCanvasProvider.endHint()
            case .minimal(let v): v.layer.borderWidth = 0
            }
        }
    }
}

extension RtcViewController: UIGestureRecognizerDelegate {
    var isScrollViewOnTop: Bool {
        guard let window = view.window else { return false }
        let scrollX = mainScrollView.convert(mainScrollView.bounds, to: window).width / 2
        return scrollX == window.center.x
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let isOnScrollView = gestureRecognizer.view?.superview is RtcItemContentView
        if !isOnScrollView { return true }
        
        guard let pan = (gestureRecognizer as? UIPanGestureRecognizer),
              let view = gestureRecognizer.view
        else { return false }
        let dragVelocity = pan.velocity(in: view)
        if isScrollViewOnTop {
            return abs(dragVelocity.y) > abs(dragVelocity.x)
        } else {
            return abs(dragVelocity.x) > abs(dragVelocity.y)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}
