//
//  ReplayOverlay.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import Foundation

protocol ReplayOverlayDelegate: AnyObject {
    func replayOverlayDidClickClose(_ overlay: ReplayOverlay)
    
    func replayOverlayDidClickPlayOrPause(_ overlay: ReplayOverlay)
}

class ReplayOverlay: NSObject {
    let labelWidth: CGFloat = 66
    let toolBarHeight: CGFloat = 50
    
    enum DisplayState {
        case showAlways
        case showDelayHide
        case hideAlways
        case hideWaitingTouch
        
        func stateOnTouch() -> DisplayState {
            switch self {
            case .showAlways:
                return .showAlways
            case .showDelayHide:
                return .hideWaitingTouch
            case .hideAlways:
                return .hideAlways
            case .hideWaitingTouch:
                return .showDelayHide
            }
        }
    }
    
    var isPause = true {
        didSet {
            let img = UIImage(named: isPause ? "play" : "pause")!
            playPauseButton.setImage(img, for: .normal)
        }
    }
    var duration: TimeInterval = 1
    
    weak var delegate: ReplayOverlayDelegate?
    
    var displayState: DisplayState = .showDelayHide {
        didSet {
            apply(displayState: displayState)
        }
    }
    
    func attachTo(parent: UIView) {
        parent.addSubview(toolBar)
        parent.addSubview(closeToolBar)
        
        toolBar.addSubview(currentTimeLabel)
        toolBar.addSubview(progressView)
        toolBar.addSubview(totalTimeLabel)
        toolBar.addSubview(playPauseButton)
        toolBar.addSubview(indicator)
        
        closeToolBar.addSubview(closeButton)
        
        indicator.isHidden = true
        indicator.snp.makeConstraints { make in
            make.edges.equalTo(playPauseButton)
        }
        
        let playWidth: CGFloat = 44
        playPauseButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(toolBarHeight - playWidth)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(playWidth)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.left.equalTo(playPauseButton.snp.right)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(labelWidth)
        }
        
        progressView.snp.makeConstraints { make in
            make.left.equalTo(currentTimeLabel.snp.right)
            make.right.equalTo(totalTimeLabel.snp.left)
            make.height.equalTo(4)
            make.centerY.equalTo(currentTimeLabel)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(currentTimeLabel)
        }
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(toolBarHeight)
            make.width.equalToSuperview().multipliedBy(0.667)
            make.bottom.equalToSuperview().inset(44)
            make.centerX.equalToSuperview()
        }
        
        closeToolBar.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview().inset(44)
            make.width.height.equalTo(44)
        }
        
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        closeButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        show()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.delegate = self
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        parent.addGestureRecognizer(doubleTap)
        parent.addGestureRecognizer(tap)
    }
    
    func getFormattedString(_ duration: TimeInterval) -> String {
        let min = Int(duration / 60)
        let sec = Int(duration) % 60
        return String(format: "%02d:%02d", min, sec)
    }
    
    func update(isPause: Bool) {
        self.isPause = isPause
    }
    
    func updateIsBuffering(_ buffering: Bool) {
        playPauseButton.isHidden = buffering
        if buffering {
            indicator.isHidden = false
            indicator.startAnimating()
        } else {
            indicator.isHidden = false
            indicator.stopAnimating()
        }
    }
    
    func updateCurrentTime(_ time: TimeInterval) {
        currentTimeLabel.text = getFormattedString(time)
        let progress = time / duration
        progressView.progress = Float(progress)
    }
    
    func updateDuration(_ duration: TimeInterval) {
        self.duration = duration
        totalTimeLabel.text = getFormattedString(duration)
    }
    
    @objc
    func onDoubleTap() {
        delegate?.replayOverlayDidClickPlayOrPause(self)
    }
    
    @objc
    func onTap() {
        displayState = displayState.stateOnTouch()
    }
    
    func apply(displayState: DisplayState) {
        switch displayState {
        case .showAlways:
            subviews.forEach { $0.isHidden = false }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.dismiss), object: nil)
        case .showDelayHide:
            subviews.forEach { $0.isHidden = false }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.dismiss), object: nil)
            perform(#selector(self.dismiss), with: nil, afterDelay: 20)
        case .hideAlways, .hideWaitingTouch:
            subviews.forEach { $0.isHidden = true }
        }
    }
    
    @objc
    func showAlways() {
        displayState = .showAlways
    }
    
    @objc
    func show() {
        displayState = .showDelayHide
    }
    
    @objc
    func onPlayOrPause() {
        delegate?.replayOverlayDidClickPlayOrPause(self)
    }
    
    @objc
    func onClose() {
        delegate?.replayOverlayDidClickClose(self)
    }
    
    @objc
    func hideAlways() {
        displayState = .hideAlways
    }
    
    @objc
    func dismiss() {
        displayState = .hideWaitingTouch
    }
    
    var subviews: [UIView] {
        return [toolBar, closeToolBar]
    }
    
    // MARK: - Lazy
    lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .white
        return label
    }()
    lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.tintColor = .white
        return view
    }()
    
    lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .white
        return label
    }()
    
    lazy var indicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let view = UIActivityIndicatorView(style: .medium)
            view.tintColor = .white
            return view
        } else {
            return UIActivityIndicatorView(style: .white)
        }
    }()
    
    lazy var toolBar: UIToolbar = {
        let bar = UIToolbar()
        bar.clipsToBounds = true
        bar.layer.cornerRadius = 10
        return bar
    }()
    
    lazy var closeToolBar: UIToolbar = {
        let bar = UIToolbar()
        bar.clipsToBounds = true
        bar.layer.cornerRadius = 10
        return bar
    }()
    
    lazy var playPauseButton: UIButton = {
        let btn =  UIButton(type: .custom)
        btn.tintColor = .white
        btn.setImage(UIImage(named: isPause ? "play" : "pause"), for: .normal)
        btn.addTarget(self, action: #selector(onPlayOrPause), for: .touchUpInside)
        return btn
    }()
    
    lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "close"), for: .normal)
        return btn
    }()
}

extension ReplayOverlay: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let tap = gestureRecognizer as? UITapGestureRecognizer,
              tap.numberOfTapsRequired == 1,
              let dTap = otherGestureRecognizer as? UITapGestureRecognizer,
              dTap.numberOfTapsRequired == 2
        else { return false }
        return true
    }
}
