//
//  InnerPermissionControlView.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/13.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

private let itemWidth = CGFloat(44)
class InnerPermissionControlView: UIView {
    enum ClickType {
        case camera
        case mic
    }
    
    var clickHandler: ((ClickType)->Void)?

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private

    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 4
        layer.borderWidth = commonBorderWidth
        setTraitRelatedBlock { v in
            v.layer.borderColor = UIColor.borderColor.cgColor
        }
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
        default:
            return
        }
    }

    // MARK: - Lazy

    lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [cameraButton, micButton])
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

}
