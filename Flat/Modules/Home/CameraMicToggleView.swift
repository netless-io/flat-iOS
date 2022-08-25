//
//  CameraMicToggleView.swift
//  Flat
//
//  Created by xuyunshi on 2022/8/25.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit

class CameraMicToggleView: UIView {
    var cameraOn: Bool
    var micOn: Bool

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
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        for view in stackView.arrangedSubviews {
            view.snp.makeConstraints { make in
                make.height.equalTo(58)
            }
        }
        
        self.cameraSwitch.isOn = cameraOn
        self.micSwitch.isOn = micOn
        self.cameraSwitch.addTarget(self, action: #selector(onSwitchUpdate(_:)), for: .valueChanged)
        self.micSwitch.addTarget(self, action: #selector(onSwitchUpdate(_:)), for: .valueChanged)
    }
    
    @objc func onSwitchUpdate(_ sender: UISwitch) {
        if sender === cameraSwitch {
            self.cameraOn = sender.isOn
        } else {
            self.micOn = sender.isOn
        }
    }
    
    func selectionView(imageName: String, title: String, detail: String, switchView: UISwitch) -> UIView {
        let view = UIView()
        let imageView = UIImageView(image: UIImage(named: imageName)?.tintColor(.brandColor))
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerX.equalTo(view.snp.left).offset(28)
            make.top.equalTo(11)
        }
        let label1 = UILabel()
        label1.text = title
        label1.font = .systemFont(ofSize: 16)
        label1.textColor = .strongText
        view.addSubview(label1)
        label1.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(56)
            make.top.equalToSuperview()
        }
        let label2 = UILabel()
        label2.text = detail
        label2.font = .systemFont(ofSize: 12)
        label2.textColor = .text
        view.addSubview(label2)
        label2.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(56)
            make.top.equalToSuperview().inset(28)
        }
        let line = UIView()
        view.addSubview(line)
        line.backgroundColor = .borderColor
        line.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(1/UIScreen.main.scale)
            make.left.equalToSuperview().inset(56)
            make.right.equalToSuperview().inset(16)
        }
        view.addSubview(switchView)
        switchView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        return view
    }
    
    lazy var stackView = UIStackView(arrangedSubviews: [
        selectionView(imageName: "camera", title: localizeStrings("Camera"), detail: localizeStrings("JoinCameraDetail"), switchView: cameraSwitch),
        selectionView(imageName: "microphone", title: localizeStrings("Mic"), detail: localizeStrings("JoinMicDetail"), switchView: micSwitch),
    ])
    lazy var cameraSwitch = UISwitch()
    lazy var micSwitch = UISwitch()
}
