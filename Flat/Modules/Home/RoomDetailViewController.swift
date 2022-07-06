//
//  RoomDetailViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift

class RoomDetailViewController: UIViewController {
    enum RoomOperation {
        case modify
        case remove
        case cancel
        
        var isDestructive: Bool {
            if self == .cancel { return true }
            return false
        }
        
        var title: String {
            switch self {
            case .cancel:
                return NSLocalizedString("Cancel Room", comment: "")
            case .remove:
                return NSLocalizedString("Remove From List", comment: "")
            case .modify:
                return NSLocalizedString("Modify Room", comment: "")
            }
        }
        
        var alertVerbose: String {
            switch self {
            case .modify:
                return ""
            case .remove:
                return NSLocalizedString("Remove Room Verbose", comment: "")
            case .cancel:
                return NSLocalizedString("Cancel Room Verbose", comment: "")
            }
        }
        
        func actionFor(viewController: RoomDetailViewController) {
            switch self {
            case .modify:
                // TODO: Modify Room 
                return
            case .remove, .cancel:
                let hud = viewController.showActivityIndicator()
                let api = RoomCancelRequest(roomUUID: viewController.info.roomUUID)
                ApiProvider.shared.request(fromApi: api) { result in
                    switch result {
                    case .success:
                        NotificationCenter.default.post(name: .init(rawValue: homeShouldUpdateListNotification), object: nil)
                        hud.stopAnimating()
                        
                        viewController.navigationController?.popViewController(animated: true)
                        viewController.mainContainer?.removeTop()
                    case .failure(let error):
                        hud.stopAnimating()
                        viewController.toast(error.localizedDescription)
                    }
                }
            }
        }
        
        static func actionsWith(isTeacher: Bool, roomStatus: RoomStartStatus) -> [RoomOperation] {
            switch roomStatus {
            case .Idle:
                if isTeacher {
                    return [.modify, .cancel]
                } else {
                    return [.remove]
                }
            case .Started, .Paused:
                if isTeacher {
                    return []
                } else {
                    return [.remove]
                }
            default:
                return []
            }
        }
    }
    
    var info: RoomBasicInfo
    var availableOperations: [RoomOperation] = []
    
    let deviceStatusStore: UserDevicePreferredStatusStore
    
    var cameraOn: Bool
    
    var micOn: Bool
    
    func updateStatus(_ status: RoomStartStatus) {
        info.roomStatus = status
        if isViewLoaded {
            updateEnterRoomButtonTitle()
        }
    }
    
    init(info: RoomBasicInfo) {
        self.info = info
        deviceStatusStore = UserDevicePreferredStatusStore(userUUID: AuthStore.shared.user?.userUUID ?? "")
        self.cameraOn = deviceStatusStore.getDevicePreferredStatus(.camera)
        self.micOn = deviceStatusStore.getDevicePreferredStatus(.mic)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - LifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData { _ in
            self.updateViewWithCurrentStatus()
            self.updateAvailableActions()
            self.updateEnterRoomButtonTitle()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateViewWithCurrentStatus()
        updateAvailableActions()
        updateEnterRoomButtonTitle()
    }
    
    // MARK: - Private
    func loadData(completion: @escaping ((Result<RoomBasicInfo, ApiError>)->Void)) {
        RoomBasicInfo.fetchInfoBy(uuid: info.roomUUID, periodicUUID: info.periodicUUID) { result in
            switch result {
            case .success(let detail):
                self.info = detail
                completion(.success(detail))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateAvailableActions() {
        let isTeacher = info.isOwner
        availableOperations = RoomOperation.actionsWith(isTeacher: isTeacher, roomStatus: info.roomStatus)
        if availableOperations.isEmpty {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more"), style: .plain, target: self, action: #selector(onClickEdit(_:)))
        }
    }

    @objc func onClickEdit(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        for action in availableOperations {
            alertController.addAction(.init(title: action.title, style: action.isDestructive ? .destructive : .default, handler: { _ in
                if !action.alertVerbose.isEmpty {
                    self.showCheckAlert(title: action.title, message: action.alertVerbose) {
                        action.actionFor(viewController: self)
                    }
                }
            }))
        }
        alertController.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        popoverViewController(viewController: alertController, fromItem: sender)
    }
    
    func setupViews() {
        view.backgroundColor = .whiteBG
        mainStackView.backgroundColor = .whiteBG
        mainStackView.arrangedSubviews.forEach {
            $0.backgroundColor = .whiteBG
        }
        startTimeLabel.textColor = .text
        startDateLabel.textColor = .text
        endDateLabel.textColor = .text
        endTimeLabel.textColor = .text
        durationLabel.textColor = .text
        durationLabel.backgroundColor = .cellSelectedBG
        statusLabel.textColor = .text
        
        roomTypeLabel.textColor = .text
        roomNumberLabel.textColor = .text
        
        roomTypeTitleLabel.textColor = .subText
        roomNumberTitleLabel.textColor = .subText
        
        navigationItem.title = NSLocalizedString("Room Detail", comment: "")
        var j = 0
        for i in 1...mainStackView.arrangedSubviews.count - 1 {
            let line = UIView()
            line.backgroundColor = .borderColor
            mainStackView.insertArrangedSubview(line, at: i + j)
            line.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            j += 1
        }
        
        view.addSubview(replayButton)
        replayButton.snp.makeConstraints { make in
            make.top.bottom.right.equalTo(roomOperationStackView)
        }
    }
    
    func updateEnterRoomButtonTitle() {
        if self.info.isOwner, info.roomStatus == .Idle {
            self.enterRoomButton.setTitle(NSLocalizedString("Start Class", comment: ""), for: .normal)
        } else {
            self.enterRoomButton.setTitle(NSLocalizedString("Enter Room", comment: ""), for: .normal)
        }
    }
    
    func updateViewWithCurrentStatus() {
        let beginTime: Date
        let endTime: Date
        let status: RoomStartStatus
        let roomType: ClassRoomType
        beginTime = info.beginTime
        endTime = info.endTime
        status = info.roomStatus
        roomType = info.roomType
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        startTimeLabel.text = formatter.string(from: beginTime)
        endTimeLabel.text = formatter.string(from: endTime)
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        startDateLabel.text = formatter.string(from: beginTime)
        endDateLabel.text = formatter.string(from: endTime)
        
        var duration = info.endTime.timeIntervalSince(beginTime)
        duration = ceil(duration / 60) * 60
        
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .brief
        durationFormatter.maximumUnitCount = 1
        durationFormatter.zeroFormattingBehavior = .dropAll
        durationFormatter.calendar?.locale = Locale(identifier: LocaleManager.language?.code ?? "")
        durationFormatter.allowedUnits = [.day, .hour, .minute, .second]
        if var durationStr = durationFormatter.string(from: duration) {
            if durationStr.hasPrefix("-") {
                durationStr = String(durationStr.dropFirst())
            }
            durationLabel.text = durationStr
        }
        
        let displayStatus = status.getDisplayStatus()
        statusLabel.text = NSLocalizedString(displayStatus.rawValue, comment: "")
        statusLabel.textColor = displayStatus.textColor
        
        roomNumberLabel.text = info.formatterInviteCode
        roomTypeLabel.text = NSLocalizedString(roomType.rawValue, comment: "")
        
        if status == .Stopped {
            roomOperationStackView.arrangedSubviews.forEach { $0.isHidden = true }
            replayButton.isEnabled = info.hasRecord
        } else {
            replayButton.isHidden = true
        }
    }
    
    // MARK: - Action
    @objc func onClickReplay() {
        showActivityIndicator()
        ApiProvider.shared.request(fromApi: RecordDetailRequest(uuid: info.roomUUID)) { [weak self] result in
            guard let self = self else { return }
            self.stopActivityIndicator()
            switch result {
            case .success(let recordInfo):
                let vc = ReplayViewController(info: recordInfo)
                self.mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    @IBAction func onClickInvite(_ sender: UIButton) {
        let vc = ShareManager.createShareActivityViewController(roomUUID: info.roomUUID,
                                                                beginTime: info.beginTime,
                                                                title: info.title,
                                                                roomNumber: info.inviteCode)
        popoverViewController(viewController: vc, fromSource: sender)
    }
    
    @IBAction func onClickEnterRoom(_ sender: Any) {
        enterRoomButton.isEnabled = false
        
        // Join room
        RoomPlayInfo.fetchByJoinWith(uuid: info.roomUUID, periodicUUID: info.periodicUUID) { [weak self] result in
            guard let self = self else { return }
            self.enterRoomButton.isEnabled = true
            switch result {
            case .success(let playInfo):
                let vc = ClassRoomFactory.getClassRoomViewController(withPlayInfo: playInfo,
                                                                     detailInfo: self.info,
                                                                     deviceStatus: .init(mic: self.micOn, camera: self.cameraOn))
                self.mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
            case .failure(let error):
                self.showAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    @IBOutlet weak var roomTypeTitleLabel: UILabel!
    @IBOutlet weak var roomNumberTitleLabel: UILabel!
    @IBOutlet weak var enterRoomButton: UIButton!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var roomTypeLabel: UILabel!
    @IBOutlet weak var roomNumberLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var roomOperationStackView: UIStackView!
    
    lazy var replayButton: FlatGeneralButton = {
        let btn = FlatGeneralButton(type: .custom)
        btn.setTitle(NSLocalizedString("Replay", comment: ""), for: .normal)
        btn.addTarget(self, action: #selector(onClickReplay), for: .touchUpInside)
        return btn
    }()
}
