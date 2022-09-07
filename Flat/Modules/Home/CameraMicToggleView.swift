//
//  CameraMicToggleView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraMicToggleViewDelegate: AnyObject {
    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, cameraOn: Bool) -> Bool
    func cameraMicToggleViewCouldUpdate(_ view: CameraMicToggleView, micOn: Bool) -> Bool
}

class CameraMicToggleView: UIView {
    weak var delegate: CameraMicToggleViewDelegate?
    
    var cameraOnUpdate: ((Bool)->Void)?
    var micOnUpdate: ((Bool)->Void)?
    
    var cameraOn: Bool {
        didSet {
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            cameraButton.isSelected = cameraOn
            cameraOnUpdate?(cameraOn)
        }
    }
    
    var micOn: Bool {
        didSet {
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            microphoneButton.isSelected = micOn
            micOnUpdate?(micOn)
        }
    }

    init(cameraOn: Bool, micOn: Bool) {
        self.cameraOn = cameraOn
        self.micOn = micOn
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        self.cameraOn = false
        self.micOn = false
        super.init(coder: coder)
        setupViews()
    }

    let itemWidth: CGFloat = 48
    
    override var intrinsicContentSize: CGSize {
        let count = CGFloat(2) //CGFloat(stackView.arrangedSubviews.count)
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
        if sender === cameraButton {
            if let delegate = delegate, !cameraOn {
                if delegate.cameraMicToggleViewCouldUpdate(self, cameraOn: !self.cameraOn) {
                    self.cameraOn.toggle()
                }
            } else {
                self.cameraOn.toggle()
            }
        } else {
            if let delegate = delegate, !micOn {
                if delegate.cameraMicToggleViewCouldUpdate(self, micOn: !self.micOn) {
                    self.micOn.toggle()
                }
            } else {
                self.micOn.toggle()
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
