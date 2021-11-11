//
//  RoomDetailViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/11/1.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

class RoomDetailViewController: UIViewController {
    let info: RoomListInfo
    var detailInfo: RoomInfo?
    
    init(info: RoomListInfo) {
        self.info = info
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
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateViewWithCurrentStatus()
    }
    
    // MARK: - Private
    func loadData(completion: @escaping ((Result<RoomInfo, ApiError>)->Void)) {
        RoomInfo.fetchInfoBy(uuid: info.roomUUID) { result in
            switch result {
            case .success(let detail):
                self.detailInfo = detail
                completion(.success(detail))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setupViews() {
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
    }
    
    func updateViewWithCurrentStatus() {
        let beginTime: Date
        let endTime: Date
        let status: RoomStartStatus
        let roomType: ClassRoomType
        if let detailInfo = detailInfo {
            beginTime = detailInfo.beginTime
            endTime = detailInfo.endTime
            status = detailInfo.roomStatus
            roomType = detailInfo.roomType
        } else {
            beginTime = info.beginTime
            endTime = info.endTime
            status = info.roomStatus
            roomType = info.roomType
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        startTimeLabel.text = formatter.string(from: beginTime)
        endTimeLabel.text = formatter.string(from: endTime)
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        startDateLabel.text = formatter.string(from: beginTime)
        endDateLabel.text = formatter.string(from: endTime)
        
        let duration = info.endTime.timeIntervalSince(beginTime)
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .brief
        durationFormatter.allowedUnits = [.hour, .minute]
        durationLabel.text = durationFormatter.string(from: duration)
        
        statusLabel.text = NSLocalizedString(status.rawValue, comment: "")
        statusLabel.textColor = status.textColor
        
        roomNumberLabel.text = info.roomUUID
        roomTypeLabel.text = NSLocalizedString(roomType.rawValue, comment: "")
    }
    
    // MARK: - Action
    @IBAction func onClickInvite(_ sender: UIButton) {
        guard let detailInfo = detailInfo else {
            showActivityIndicator()
            loadData { result in
                self.stopActivityIndicator()
                switch result {
                case .success:
                    self.onClickInvite(sender)
                case .failure(let error):
                    self.showAlertWith(message: error.localizedDescription)
                }
            }
            return
        }
        
        let vc = InviteViewController(roomInfo: detailInfo,
                             roomUUID: info.roomUUID,
                             userName: AuthStore.shared.user?.name ?? "")
        popoverViewController(viewController: vc, fromSource: sender)
    }
    
    @IBAction func onClickEnterRoom(_ sender: Any) {
        guard let detailInfo = detailInfo else {
            showActivityIndicator()
            loadData { result in
                self.stopActivityIndicator()
                switch result {
                case .success:
                    self.onClickEnterRoom(sender)
                case .failure(let error):
                    self.showAlertWith(message: error.localizedDescription)
                }
            }
            return
        }
        
        showActivityIndicator()
        RoomPlayInfo.fetchByJoinWith(uuid: info.roomUUID) { result in
            self.stopActivityIndicator()
            switch result {
            case .success(let playInfo):
                // TODO: Update camara and mic
                let vc = ClassRoomViewController(roomPlayInfo: playInfo, roomInfo: detailInfo, cameraOn: false, micOn: false)
                vc.modalPresentationStyle = .fullScreen
                if let split = self.splitViewController {
                    split.present(vc, animated: true, completion: nil)
                } else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let error):
                self.showAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var roomTypeLabel: UILabel!
    @IBOutlet weak var roomNumberLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
}
