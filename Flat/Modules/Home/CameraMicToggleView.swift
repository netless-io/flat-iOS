//
//  CameraMicToggleView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class CameraMicToggleView: UIView {
    var cameraOnUpdate: ((Bool)->Void)?
    var micOnUpdate: ((Bool)->Void)?
    
    var cameraOn: Bool {
        didSet {
            cameraOnUpdate?(cameraOn)
        }
    }
    
    var micOn: Bool {
        didSet {
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
    
    func setupViews() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.arrangedSubviews.first?.snp.makeConstraints { make in
            make.width.equalTo(stackView.snp.height)
        }
        
        cameraButton.isSelected = cameraOn
        microphoneButton.isSelected = micOn
    }
    
    @objc func onButtonClick(_ sender: UIButton) {
        if sender === cameraButton {
            self.cameraOn.toggle()
        } else {
            self.micOn.toggle()
        }
        sender.isSelected.toggle()
    }
    
    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "camera"), for: .selected)
        button.setImage(UIImage(named: "camera_off"), for: .normal)
        button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var microphoneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "microphone"), for: .selected)
        button.setImage(UIImage(named: "mic_off"), for: .normal)
        button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stackView = UIStackView(arrangedSubviews: [cameraButton, microphoneButton])
}
