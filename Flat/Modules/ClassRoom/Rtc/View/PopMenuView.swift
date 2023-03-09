//
//  PopMenuView.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/3.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class PopMenuView: UIView {
    enum Direction {
        case top
        case left
        case bottom
        case right
    }

    var dismissHandle: (() -> Void)?
    weak var sourceView: UIView?
    var insets: UIEdgeInsets = .zero
    var direction: Direction = .bottom

    func dismiss() {
        bg.removeFromSuperview()
        removeFromSuperview()
        dismissHandle?()
        sourceView = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            sourceView = nil
        }
    }

    @objc func onTapBg(_: UITapGestureRecognizer) {
        dismiss()
    }

    lazy var bg: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.03)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapBg(_:))))
        return view
    }()

    func updateMenuFrame() {
        guard
            let source = sourceView,
            let target = source.window
        else { return }
        let x: CGFloat
        let y: CGFloat
        // Fix for source auto layout..
        source.superview?.setNeedsLayout()
        source.superview?.layoutIfNeeded()
        let sOrigin = source.convert(CGPoint.zero, to: target)
        switch direction {
        case .left:
            x = sOrigin.x - intrinsicContentSize.width + insets.left
            y = sOrigin.y + insets.top - insets.bottom + ((source.bounds.height - intrinsicContentSize.height) / 2)
        case .right:
            x = sOrigin.x + source.bounds.width - insets.right
            y = sOrigin.y + insets.top - insets.bottom + ((source.bounds.height - intrinsicContentSize.height) / 2)
        case .top:
            y = sOrigin.y - intrinsicContentSize.height + insets.top
            x = sOrigin.x + insets.left - insets.right + ((source.bounds.width - intrinsicContentSize.width) / 2)
        case .bottom:
            y = sOrigin.y + source.bounds.height - insets.bottom
            x = sOrigin.x + insets.left - insets.right + ((source.bounds.width - intrinsicContentSize.width) / 2)
        }
        frame = .init(origin: .init(x: x, y: y), size: intrinsicContentSize)
    }

    func show(fromSource source: UIView?,
              direction: Direction,
              insets: UIEdgeInsets)
    {
        if source == sourceView { return }
        sourceView = source
        guard let target = source?.window else { return }
        if superview == nil {
            target.addSubview(bg)
            target.addSubview(self)
            bg.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        self.insets = insets
        self.direction = direction
        updateMenuFrame()
    }
}
