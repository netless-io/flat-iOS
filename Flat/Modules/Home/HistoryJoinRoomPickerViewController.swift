//
//  HistoryJoinRoomPickerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/11/21.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

class HistoryJoinRoomPickerViewController: UIViewController {
    var items = ClassroomCoordinator.shared.joinRoomHisotryItems
    var dismissHandler: (()->Void)?
    
    var roomIdConfirmHandler: ((String) ->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func triggerDismissHandler() {
        dismissHandler?()
        dismissHandler = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        triggerDismissHandler()
    }
    
    func setupViews() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        let operationStack = UIStackView(arrangedSubviews: [clearButton, UIView(), confirmButton])
        operationStack.addLine(direction: .bottom, color: .borderColor, width: commonBorderWidth, inset: .init(top: 0, left: 14, bottom: 0, right: 14))
        operationStack.axis = .horizontal
        
        let stack = UIStackView(arrangedSubviews: [operationStack, picker, cancelButton])
        stack.backgroundColor = .color(type: .background)
        stack.axis = .vertical
        view.addSubview(stack)
        operationStack.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        stack.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        picker.snp.makeConstraints { make in
            make.height.equalTo(144)
        }
        cancelButton.snp.makeConstraints { $0.height.equalTo(44) }
        fillBottomSafeAreaWith(color: .color(type: .background))
    }
    
    @objc func onCancel() {
        triggerDismissHandler()
    }
    
    @objc func onConfirm() {
        let row = picker.selectedRow(inComponent: 0)
        if row + 1 > items.count {
            triggerDismissHandler()
            return
        }
        let item = items[row]
        triggerDismissHandler()
        roomIdConfirmHandler?(item.roomInviteId)
    }
    
    @objc func onClear() {
        ClassroomCoordinator.shared.clearJoinRoomHistoryItem()
        triggerDismissHandler()
    }
    
    lazy var picker: UIPickerView = {
        let view = UIPickerView()
        view.backgroundColor = .color(type: .background)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    lazy var clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(localizeStrings("ClearHistory"), for: .normal)
        btn.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        btn.tintColor = .color(type: .text)
        btn.contentEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 14)
        return btn
    }()
    
    lazy var confirmButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(localizeStrings("Confirm"), for: .normal)
        btn.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        btn.tintColor = .color(type: .primary)
        btn.contentEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 14)
        return btn
    }()
    
    lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(localizeStrings("Cancel"), for: .normal)
        btn.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        btn.tintColor = .color(type: .text)
        return btn
    }()
}

extension HistoryJoinRoomPickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        items.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: .zero)
        let leftLabel = UILabel()
        leftLabel.font = .systemFont(ofSize: 14)
        leftLabel.textColor = .color(type: .text)
        leftLabel.numberOfLines = 1
        leftLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leftLabel.text = items[row].roomName
        leftLabel.textAlignment = .left
        
        let rightLabel = UILabel()
        rightLabel.font = .systemFont(ofSize: 14)
        rightLabel.textColor = .color(type: .text)
        rightLabel.text = items[row].roomInviteId.formatterInviteCode
        rightLabel.textAlignment = .right
        
        let stack = UIStackView(arrangedSubviews: [leftLabel, rightLabel])
        stack.spacing = 14
        stack.axis = .horizontal
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
        }
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        44
    }
}
