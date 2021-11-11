//
//  ClassRoomSettingViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

protocol ClassRoomSettingViewControllerDelegate: AnyObject {
    func classRoomSettingViewControllerDidUpdateControl(_ vc: ClassRoomSettingViewController, type: ClassRoomSettingViewController.ControlType, isOn: Bool)
    
    func classRoomSettingViewControllerDidClickLeave(_ controller: ClassRoomSettingViewController)
}

class ClassRoomSettingViewController: PopOverDismissDetectableViewController {
    enum ControlType {
        case camera
        case mic
        case videoArea
        
        var description: String {
            switch self {
            case .camera:
                return NSLocalizedString("Camera", comment: "")
            case .mic:
                return NSLocalizedString("Mic", comment: "")
            case .videoArea:
                return NSLocalizedString("Video Area", comment: "")
            }
        }
    }
    
    weak var delegate: ClassRoomSettingViewControllerDelegate?
    let cellIdentifier = "cellIdentifier"
    
    var cameraOn: Bool {
        didSet {
            tableView.reloadData()
        }
    }
    var micOn: Bool {
        didSet {
            tableView.reloadData()
        }
    }
    var videoAreaOn: Bool {
        didSet {
            tableView.reloadData()
        }
    }
    var models: [ControlType] = [.camera, .mic, .videoArea]
    
    // MARK: - LifeCycle
    init(cameraOn: Bool,
         micOn: Bool,
         videoAreaOn: Bool) {
        self.cameraOn = cameraOn
        self.micOn = micOn
        self.videoAreaOn = videoAreaOn
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(topView)
        let topViewHeight: CGFloat = 34
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(topViewHeight)
        }
        
        let bottomContainer = UIView(frame: .init(origin: .zero, size: .init(width: 240, height: 64)))
        bottomContainer.addSubview(logoutButton)
        tableView.tableFooterView = bottomContainer
        logoutButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
        
        tableView.contentInset = .init(top: topViewHeight, left: 0, bottom: 0, right: 0)
        preferredContentSize = .init(width: 240, height: 205)
    }
    
    func config(cell: ClassRoomSettingTableViewCell, type: ControlType) {
        cell.label.text = type.description
        switch type {
        case .camera:
            cell.switch.isOn = cameraOn
        case .mic:
            cell.switch.isOn = micOn
        case .videoArea:
            cell.switch.isOn = videoAreaOn
        }
        cell.switchValueChangedHandler = { [weak self] isOn in
            guard let self = self else { return }
            self.delegate?.classRoomSettingViewControllerDidUpdateControl(self, type: type, isOn: isOn)
        }
    }
    
    @objc func onClickLeave() {
        delegate?.classRoomSettingViewControllerDidClickLeave(self)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Lazy
    lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.init(hexString: "#F45454"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setImage(UIImage(named: "logout")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.layer.borderColor = UIColor.init(hexString: "#F45454").cgColor
        button.layer.borderWidth = 1 / UIScreen.main.scale
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.contentEdgeInsets = .init(top: 0, left: 20, bottom: 0, right: 20)
        button.setTitle(NSLocalizedString("Leaving Classroom", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(onClickLeave), for: .touchUpInside)
        return button
    }()
    
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        let topLabel = UILabel(frame: .zero)
        topLabel.text = NSLocalizedString("Setting", comment: "")
        topLabel.textColor = .text
        topLabel.font = .systemFont(ofSize: 12, weight: .medium)
        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(.init(nibName: String(describing: ClassRoomSettingTableViewCell.self), bundle: nil), forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 37
        view.showsVerticalScrollIndicator = false
        return view
    }()
}

extension ClassRoomSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ClassRoomSettingTableViewCell
        let type = models[indexPath.row]
        config(cell: cell, type: type)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
