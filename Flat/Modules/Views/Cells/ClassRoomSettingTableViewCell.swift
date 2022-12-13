//
//  ClassRoomSettingTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/29.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class ClassRoomSettingTableViewCell: UITableViewCell {
    var switchValueChangedHandler: ((Bool) -> Void)?
    var cameraFaceFrontChangedHandler: ((Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .classroomChildBG
        contentView.backgroundColor = .classroomChildBG
        label.textColor = .color(type: .text)
        lineHeightConstraint.constant = commonBorderWidth
        borderView.backgroundColor = .borderColor

        iconView.setTraitRelatedBlock { v in
            v.image = v.image?.tintColor(.color(type: .text).resolvedColor(with: v.traitCollection))
        }

        rightArrowImageView.setTraitRelatedBlock { v in
            v.image = v.image?.tintColor(.color(type: .text).resolvedColor(with: v.traitCollection))
        }

        contentView.addSubview(rightArrowImageView)
        rightArrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }

        cameraToggleView.setTitleTextAttributes([.foregroundColor: UIColor.color(type: .text)], for: .normal)
        cameraToggleView.setTitle(localizeStrings("Camera.front"), forSegmentAt: 0)
        cameraToggleView.setTitle(localizeStrings("Camera.rear"), forSegmentAt: 1)
        cameraToggleView.addTarget(self, action: #selector(onCameraFaceUpdate), for: .valueChanged)
    }

    @objc func onCameraFaceUpdate(_ sender: UISegmentedControl) {
        cameraFaceFrontChangedHandler?(sender.selectedSegmentIndex == 0)
    }

    @IBAction func valueChanged(_ sender: UISwitch) {
        switchValueChangedHandler?(sender.isOn)
    }

    func setEnable(_ enable: Bool) {
        `switch`.isEnabled = enable
        label.textColor = enable ? .color(type: .text) : UIColor.color(type: .text).withAlphaComponent(0.5)
        iconView.alpha = enable ? 1 : 0.5
    }

    @IBOutlet var cameraToggleView: UISegmentedControl!
    @IBOutlet var borderView: UIView!
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var lineHeightConstraint: NSLayoutConstraint!
    @IBOutlet var label: UILabel!
    @IBOutlet var `switch`: UISwitch!

    lazy var rightArrowImageView = UIImageView(image: UIImage(named: "right")?.tintColor(.color(type: .text)))
}
