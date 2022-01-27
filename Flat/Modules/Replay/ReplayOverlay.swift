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
    
    func replayOverlayDidClickSeekToPercent(_ overlay: ReplayOverlay, percent: Float)
    
    func replayOverlayDidClickForward(_ overlay: ReplayOverlay)
    
    func replayOverlayDidClickBackward(_ overlay: ReplayOverlay)
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
        closeToolBar.addSubview(closeButton)
        closeToolBar.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(44)
            make.width.height.equalTo(44)
        }
        
        closeButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        toolBar.snp.makeConstraints { make in
            make.height.equalTo(toolBarHeight)
            make.width.equalToSuperview().multipliedBy(0.667)
            make.bottom.equalToSuperview().inset(44)
            make.centerX.equalToSuperview()
        }
        
        toolBar.addSubview(toolStackView)
        toolStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backwardButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        
        forwardButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.width.equalTo(playPauseButton.snp.height)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(labelWidth)
        }
        
        progressView.snp.makeConstraints { make in
            make.height.equalTo(4)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(currentTimeLabel)
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
        playPauseButton.imageView?.isHidden = buffering
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
    func onProgressTapGesture(_ tap: UITapGestureRecognizer) {
        guard let view = tap.view else { return }
        let x = tap.location(in: view).x
        let width = view.bounds.width
        let progress = x / width
        delegate?.replayOverlayDidClickSeekToPercent(self, percent: Float(progress))
    }
    
    @objc
    func onForward() {
        delegate?.replayOverlayDidClickForward(self)
    }
    
    @objc
    func onBackward() {
        delegate?.replayOverlayDidClickBackward(self)
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
        return [toolBar, closeToolBar, closeButton]
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
    
    lazy var progressContainer: UIView = {
        let view = UIView()
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(4)
            make.centerY.equalToSuperview()
        }
        let progressGesture = UITapGestureRecognizer(target: self, action: #selector(onProgressTapGesture(_:)))
        view.addGestureRecognizer(progressGesture)
        return view
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
        bar.barStyle = .black
        bar.clipsToBounds = true
        bar.layer.cornerRadius = 10
        return bar
    }()
    
    lazy var toolStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [backwardButton, playPauseButton, forwardButton, currentTimeLabel, progressContainer, totalTimeLabel])
        view.distribution = .fill
        view.axis = .horizontal
        return view
    }()
    
    lazy var closeToolBar: UIToolbar = {
        let bar = UIToolbar()
        bar.barStyle = .black
        bar.clipsToBounds = true
        if #available(iOS 13.0, *) {
            bar.layer.cornerRadius = 22
        } else {
            bar.layer.cornerRadius = 10
        }
        return bar
    }()
    
    lazy var forwardButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let img = UIImage(systemName: "goforward.15", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("+15s", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(onForward), for: .touchUpInside)
        return btn
    }()
    
    lazy var backwardButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let img = UIImage(systemName: "gobackward.15", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle("-15s", for: .normal)
        }
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(onBackward), for: .touchUpInside)
        return btn
    }()
    
    lazy var playPauseButton: UIButton = {
        let btn =  UIButton(type: .custom)
        btn.tintColor = .white
        btn.setImage(UIImage(named: isPause ? "play" : "pause"), for: .normal)
        btn.addTarget(self, action: #selector(onPlayOrPause), for: .touchUpInside)
        
        btn.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        indicator.isHidden = true
        return btn
    }()
    
    lazy var closeButton: UIButton = {
        if #available(iOS 13.0, *) {
            let btn = UIButton(type: .close)
            btn.tintColor = .white
            btn.addTarget(self, action: #selector(onClose), for: .touchUpInside)
            return btn
        }
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "close"), for: .normal)
        btn.addTarget(self, action: #selector(onClose), for: .touchUpInside)
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
