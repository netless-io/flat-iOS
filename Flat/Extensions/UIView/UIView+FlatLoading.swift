//
//  UIView+Loading.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/19.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Kingfisher
import UIKit
import Lottie

private class FlatLoadingView: UIView {
    var cancelHandler: (() -> Void)?

    func currentLottieFileName() -> String {
        let isDark = traitCollection.userInterfaceStyle == .dark
        return isDark ? "loading_dark" : "loading"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        loadingView.animation = LottieAnimation.named(currentLottieFileName())
        loadingView.play()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .color(type: .background, .weak)
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview().multipliedBy(0.2)
        }

        addSubview(cancelButton)
        cancelButton.layer.borderColor = UIColor.color(type: .primary).cgColor
        cancelButton.layer.borderWidth = commonBorderWidth
        cancelButton.layer.cornerRadius = 4
        cancelButton.addTarget(self, action: #selector(onClickCancel), for: .touchUpInside)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitleColor(.color(type: .primary), for: .normal)
        cancelButton.setTitle(localizeStrings("Cancel"), for: .normal)
        cancelButton.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        cancelButton.snp.makeConstraints { make in
            make.centerX.equalTo(loadingView)
            make.top.equalTo(loadingView.snp.bottom)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onClickCancel() {
        cancelHandler?()
    }

    func startAnimating() {
        loadingView.play()
    }

    func stopAnimating() {
        loadingView.stop()
    }

    lazy var cancelButton = UIButton(type: .custom)

    lazy var loadingView: LottieAnimationView = {
        let view = LottieAnimationView(name: currentLottieFileName())
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        return view
    }()
}

extension UIView {
    func startFlatLoading(showCancelDelay: TimeInterval = .infinity,
                          cancelCompletion: (() -> Void)? = nil)
    {
        if flatLoadingView.superview == nil {
            addSubview(flatLoadingView)
            flatLoadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        bringSubviewToFront(flatLoadingView)
        flatLoadingView.isHidden = false
        flatLoadingView.alpha = 1

        flatLoadingView.startAnimating()
        flatLoadingView.cancelButton.isHidden = true
        flatLoadingView.cancelHandler = { [weak self] in
            cancelCompletion?()
            self?.endFlatLoading()
        }
        if showCancelDelay.isFinite {
            DispatchQueue.main.asyncAfter(deadline: .now() + showCancelDelay) {
                guard self.flatLoadingView.superview != nil else { return }
                self.flatLoadingView.cancelButton.isHidden = false
                self.flatLoadingView.cancelButton.alpha = 0.5
                UIView.animate(withDuration: 0.3) {
                    self.flatLoadingView.cancelButton.alpha = 1
                }
            }
        }
    }

    func endFlatLoading(withDelay delay: TimeInterval = 0.5) {
        if delay <= 0 {
            flatLoadingView.stopAnimating()
            flatLoadingView.removeFromSuperview()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.flatLoadingView.alpha = 1
                UIView.animate(withDuration: 0.3) {
                    self.flatLoadingView.alpha = 0.1
                } completion: { finish in
                    guard finish else { return }
                    self.flatLoadingView.stopAnimating()
                    self.flatLoadingView.removeFromSuperview()
                }
            }
        }
    }

    private var flatLoadingView: FlatLoadingView {
        let flatLoadingViewTag = 555
        let flatLoadingView: FlatLoadingView
        if let tagView = viewWithTag(flatLoadingViewTag) as? FlatLoadingView {
            flatLoadingView = tagView
        } else {
            flatLoadingView = FlatLoadingView(frame: .zero)
            flatLoadingView.tag = flatLoadingViewTag
        }
        return flatLoadingView
    }
}
