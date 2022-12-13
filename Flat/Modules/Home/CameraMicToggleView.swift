//
//  CameraMicToggleView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import AVFoundation
import UIKit

protocol CameraMicToggleViewDelegate: AnyObject {
    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, cameraOn: Bool) -> Bool
    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, micOn: Bool) -> Bool
}

class CameraMicToggleView: UIView {
    weak var delegate: CameraMicToggleViewDelegate?

    var cameraOnUpdate: ((Bool) -> Void)?
    var micOnUpdate: ((Bool) -> Void)?

    func set(cameraOn: Bool) {
        set(cameraOn: cameraOn, fireCallback: false, fireImpact: false)
    }

    func set(micOn: Bool) {
        set(micOn: micOn, fireCallback: false, fireImpact: false)
    }

    fileprivate func set(cameraOn: Bool, fireCallback: Bool, fireImpact: Bool) {
        self.cameraOn = cameraOn
        cameraButton.isSelected = cameraOn
        if fireCallback {
            cameraOnUpdate?(cameraOn)
        }
        if fireImpact {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    fileprivate func set(micOn: Bool, fireCallback: Bool, fireImpact: Bool) {
        self.micOn = micOn
        microphoneButton.isSelected = micOn
        if fireCallback {
            micOnUpdate?(micOn)
        }
        if fireImpact {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    internal fileprivate(set) var cameraOn: Bool
    internal fileprivate(set) var micOn: Bool

    init(cameraOn: Bool, micOn: Bool) {
        self.cameraOn = cameraOn
        self.micOn = micOn
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        cameraOn = false
        micOn = false
        super.init(coder: coder)
        setupViews()
    }

    let itemWidth: CGFloat = 48

    override var intrinsicContentSize: CGSize {
        let count = CGFloat(2) // CGFloat(stackView.arrangedSubviews.count)
        if stackView.axis == .vertical {
            return .init(width: itemWidth * count, height: itemWidth)
        } else {
            return .init(width: itemWidth, height: itemWidth * count)
        }
    }

    func setupViews() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.spacing = 0

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.lessThanOrEqualToSuperview()
        }
        stackView.arrangedSubviews.forEach {
            $0.snp.makeConstraints { make in
                make.width.height.equalTo(itemWidth)
            }
        }

        cameraButton.isSelected = cameraOn
        microphoneButton.isSelected = micOn
    }

    @objc func onButtonClick(_ sender: UIButton) {
        func toggleCamera() {
            set(cameraOn: !cameraOn, fireCallback: true, fireImpact: true)
        }

        func toggleMic() {
            set(micOn: !micOn, fireCallback: true, fireImpact: true)
        }

        if sender === cameraButton {
            if let delegate = delegate, !cameraOn {
                if delegate.cameraMicToggleViewCouldUpdate(self, cameraOn: !cameraOn) {
                    toggleCamera()
                }
            } else {
                toggleCamera()
            }
        } else {
            if let delegate = delegate, !micOn {
                if delegate.cameraMicToggleViewCouldUpdate(self, micOn: !micOn) {
                    toggleMic()
                }
            } else {
                toggleMic()
            }
        }
    }

    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "common_camera_on")?.tintColor(.color(type: .primary)), for: .selected)
        button.setImage(UIImage(named: "common_camera_off")?.tintColor(.color(type: .danger)), for: .normal)
        button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        return button
    }()

    lazy var microphoneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "common_mic_on")?.tintColor(.color(type: .primary)), for: .selected)
        button.setImage(UIImage(named: "common_mic_off")?.tintColor(.color(type: .danger)), for: .normal)
        button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        return button
    }()

    lazy var stackView = UIStackView(arrangedSubviews: [cameraButton, microphoneButton])
}
