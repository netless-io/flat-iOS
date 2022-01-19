//
//  ClassRoomSettingViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/15.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

class ClassRoomSettingViewController: UIViewController {
    enum SettingControlType {
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
    let cameraPublish: PublishRelay<Void> = .init()
    let micPublish: PublishRelay<Void> = .init()
    let videoAreaPublish: PublishRelay<Void> = .init()
    
    let cellIdentifier = "cellIdentifier"
    
    let cameraOn: BehaviorRelay<Bool>
    var micOn: BehaviorRelay<Bool>
    var videoAreaOn: BehaviorRelay<Bool>
    
    var models: [SettingControlType] = [.camera, .mic, .videoArea]
    
    // MARK: - LifeCycle
    init(cameraOn: Bool,
         micOn: Bool,
         videoAreaOn: Bool) {
        self.cameraOn = .init(value: cameraOn)
        self.micOn = .init(value: micOn)
        self.videoAreaOn = .init(value: videoAreaOn)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        Observable.of(cameraOn, micOn, videoAreaOn)
            .merge()
            .subscribe(with: self) { weakSelf, _ in
                weakSelf.tableView.reloadData()
            }
            .disposed(by: rx.disposeBag)

        
        logoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: rx.disposeBag)
    }

    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .whiteBG
        view.addSubview(tableView)
        view.addSubview(topView)
        let topViewHeight: CGFloat = 34
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(topViewHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.init(top: topViewHeight, left: 0, bottom: 0, right: 0))
        }
        
        let bottomContainer = UIView(frame: .init(origin: .zero, size: .init(width: 240, height: 64)))
        bottomContainer.addSubview(logoutButton)
        tableView.tableFooterView = bottomContainer
        logoutButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
        
        preferredContentSize = .init(width: 240, height: 205)
    }
    
    func config(cell: ClassRoomSettingTableViewCell, type: SettingControlType) {
        cell.label.text = type.description
        switch type {
        case .camera:
            cell.switch.isOn = cameraOn.value
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.cameraPublish.accept(())
            }
        case .mic:
            cell.switch.isOn = micOn.value
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.micPublish.accept(())
            }
        case .videoArea:
            cell.switch.isOn = videoAreaOn.value
            cell.switchValueChangedHandler = { [weak self] _ in
                self?.videoAreaPublish.accept(())
            }
        }
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
        return button
    }()
    
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .whiteBG
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
        view.backgroundColor = .whiteBG
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
