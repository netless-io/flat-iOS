//
//  RtcCellPopMenuView.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/3.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class RtcCellPopMenuView: PopMenuView {
    enum ClickType {
        case camera
        case mic
        case scale
    }

    let itemWidth: CGFloat = 44

    var clickHandler: ((ClickType) -> Void)?

    lazy var cameraOnImage = UIImage(named: "camera_on")!
    lazy var cameraOffImage = UIImage(named: "camera_off")!

    lazy var micOnImage = UIImage(named: "mic_on")!
    lazy var micOffImage = UIImage(named: "mic_off")!

    func update(cameraOn: Bool, micOn: Bool) {
        cameraButton.setImage(cameraOn ? cameraOnImage : cameraOffImage, for: .normal)
        cameraButton.tintColor = cameraOn ? .color(type: .primary) : .color(type: .danger)
        micButton.setImage(micOn ? micOnImage : micOffImage, for: .normal)
        micButton.tintColor = micOn ? .color(type: .primary) : .color(type: .danger)
    }

    override var intrinsicContentSize: CGSize {
        .init(width: CGFloat(stackView.arrangedSubviews.count) * itemWidth, height: itemWidth)
    }

    // MARK: LifeCycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: - Private

    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        layer.borderWidth = commonBorderWidth
        layer.borderColor = UIColor.borderColor.cgColor
        backgroundColor = .color(type: .background)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        for view in stackView.arrangedSubviews {
            view.snp.makeConstraints { make in
                make.width.height.equalTo(itemWidth)
            }
        }
    }

    // MARK: - Action

    @objc func onClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        switch sender.tag {
        case 0:
            clickHandler?(.camera)
        case 1:
            clickHandler?(.mic)
        case 2:
            clickHandler?(.scale)
        default:
            return
        }
    }

    // MARK: - Lazy

    lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [cameraButton, micButton, expandButton])
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()

    lazy var cameraButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.tag = 0
        btn.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        return btn
    }()

    lazy var micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.tag = 1
        btn.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        return btn
    }()

    lazy var expandButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "expand"), for: .normal)
        btn.tintColor = .color(type: .text)
        btn.tag = 2
        btn.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        return btn
    }()
}
