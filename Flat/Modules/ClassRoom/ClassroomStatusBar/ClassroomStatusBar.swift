//
//  ClassroomStatusBar.swift
//  Flat
//
//  Created by xuyunshi on 2023/1/30.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit

enum ClassroomNetworkStatus {
    case great
    case good
    case bad
    
    var image: UIImage? {
        switch self {
        case .great:
            return UIImage(named: "network-great")
        case .good:
            return UIImage(named: "network-good")
        case .bad:
            return UIImage(named: "network-bad")
        }
    }
}

class ClassroomStatusBar: UIView {
    var latency: Int? {
        didSet {
            guard let latency else { return }
            latencyCountLabel.text = "\(latency)ms"
        }
    }
    
    var networkStatus: ClassroomNetworkStatus? {
        didSet {
            guard let networkStatus else { return }
            networkStatusIcon.image = networkStatus.image
        }
    }
    
    var beginTime: Date?
    
    var timePassedString: String? {
        didSet {
            guard let timePassedString else { return }
            timeCountLabel.text = timePassedString
        }
    }
    
    deinit {
        logger.info("classroomStatusbar deinit")
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        timer?.invalidate()
        timer = nil
        if newWindow != nil {
            let t = Timer(fireAt: Date(),
                          interval: 1,
                          target: self,
                          selector: #selector(onTimer),
                          userInfo: nil,
                          repeats: true)
            RunLoop.current.add(t, forMode: .default)
            timer = t
        }
    }
    
    init(beginTime: Date) {
        self.beginTime = beginTime
        super.init(frame: .zero)
        backgroundColor = .color(type: .background)
        addSubview(latencyLabel)
        addSubview(latencyCountLabel)
        addSubview(networkStatusLabel)
        addSubview(networkStatusIcon)
        addSubview(timeLabel)
        addSubview(timeCountLabel)
        latencyLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        latencyCountLabel.snp.makeConstraints { make in
            make.left.equalTo(latencyLabel.snp.right)
            make.width.equalTo(76)
            make.centerY.equalToSuperview()
        }
        networkStatusLabel.snp.makeConstraints { make in
            make.left.equalTo(latencyCountLabel.snp.right)
            make.centerY.equalToSuperview()
        }
        networkStatusIcon.snp.makeConstraints { make in
            make.left.equalTo(networkStatusLabel.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(networkStatusIcon.snp.right).offset(32)
            make.centerY.equalToSuperview()
        }
        timeCountLabel.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right)
            make.centerY.equalToSuperview()
        }
        addLine(direction: .bottom, color: .borderColor)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var networkStatusIcon = UIImageView()
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        label.text = localizeStrings("classroomTimePassed") + ": "
        return label
    }()

    lazy var timeCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        return label
    }()
    
    lazy var networkStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        label.text = localizeStrings("network") + ":"
        return label
    }()
    
    lazy var latencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        label.text = localizeStrings("latency") + ": "
        return label
    }()
    
    lazy var latencyCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        return label
    }()
    
    @objc func onTimer() {
        guard let beginTime else { return }
        let duration = Int(Date().timeIntervalSince(beginTime))
        let hour = duration / 3600
        let minutes = duration / 60 % 60
        let seconds = duration % 60
        timePassedString = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
    }
    
    var timer: Timer?
}