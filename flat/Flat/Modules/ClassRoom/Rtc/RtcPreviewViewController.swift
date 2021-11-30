//
//  RtcPreviewViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/28.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Hero
import AgoraRtcKit

class RtcPreviewViewController: UIViewController {
    var dismissHandler: (()->Void)?

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    func showVideoPreview() {
        contentView.isHidden = false
        avatarContainer.isHidden = true
    }
    
    func showAvatar(url: URL?) {
        contentView.isHidden = true
        avatarContainer.isHidden = false
        avatarImageView.kf.setImage(with: url)
        largeAvatarImageView.kf.setImage(with: url)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = view.bounds.width
        let height = width * 72.0 / 96.0
        let size = CGSize(width: width, height: height)
        let y = (view.bounds.height - height) / 2
        contentView.frame = .init(x: 0, y: y, width: size.width, height: size.height)
        visualEffectView.frame = view.bounds
        scaleButton.sizeToFit()
        scaleButton.center = .init(x: view.center.x, y: view.bounds.height - scaleButton.bounds.size.height)
        avatarContainer.frame = view.bounds
        largeAvatarImageView.frame = view.bounds
        avatarEffectView.frame = view.bounds
        let avatarWidth = view.bounds.width * (48.0 / 112.0)
        avatarImageView.frame = .init(origin: .zero, size: .init(width: avatarWidth, height: avatarWidth))
        avatarImageView.center = view.center
        avatarImageView.layer.cornerRadius = avatarWidth / 2
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .black
        view.addSubview(visualEffectView)
        view.addSubview(contentView)
        view.addSubview(avatarContainer)
        avatarContainer.addSubview(largeAvatarImageView)
        avatarContainer.addSubview(avatarEffectView)
        avatarContainer.addSubview(avatarImageView)
        view.addSubview(scaleButton)
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }
    
    // MARK: - Action
    @objc func onScale() {
        dismiss(animated: true) {
            self.dismissHandler?()
        }
    }
    
    @objc func handlePan(_ gr: UIPanGestureRecognizer) {
        let translation = gr.translation(in: view)
        switch gr.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            guard translation.y <= 0 else {
                Hero.shared.update(0.01)
                return
            }
            Hero.shared.update(-translation.y / view.bounds.height)
        default:
            let velocity = gr.velocity(in: view)
            let total = translation.y + velocity.y
            if -total / view.bounds.height >= 0.5 {
                Hero.shared.finish()
                dismissHandler?()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
    // MARK: - Lazy
    lazy var contentView = UIView()
    
    lazy var scaleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "narrow"), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(onScale), for: .touchUpInside)
        btn.contentEdgeInsets = .init(top: 22, left: 22, bottom: 22, right: 22)
        return btn
    }()
    
    lazy var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    lazy var avatarContainer = UIView()
    
    lazy var largeAvatarImageView: UIImageView  = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    lazy var avatarEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    lazy var avatarImageView: UIImageView = {
        let view = UIImageView(frame: .init(origin: .zero, size: .init(width: 40, height: 40)))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
}
