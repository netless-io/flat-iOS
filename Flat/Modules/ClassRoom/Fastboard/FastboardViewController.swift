//
//  FastboardViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/1/12.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Fastboard
import Whiteboard
import RxSwift
import RxRelay

class FastboardViewController: UIViewController {
    let fastRoom: FastRoom
    let isRoomJoined: BehaviorRelay<Bool> = .init(value: false)
    var previewHandler: ((WhiteRoom, UIButton)->Void)?
    
    // MARK: Public
    func leave() {
        fastRoom.disconnectRoom()
    }
    
    init(fastRoomConfiguration: FastRoomConfiguration) {
        self.fastRoom = Fastboard.createFastRoom(withFastRoomConfig: fastRoomConfiguration)
        super.init(nibName: nil, bundle: nil)
        self.fastRoom.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        joinRoom()
    }
    
    // MARK: - Action
    @objc func rebindFromError() {
        hideErrorView()
        joinRoom()
    }
    
    // MARK: - Private
    func joinRoom() {
        showActivityIndicator()
        fastRoom.joinRoom { [weak self] result in
            self?.stopActivityIndicator()
            switch result {
            case .success:
                self?.isRoomJoined.accept(true)
            case .failure:
                return
            }
        }
    }
    
    func setupViews() {
        view.addSubview(fastRoom.view)
        fastRoom.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let saveItem = JustExecutionItem(image: UIImage(named: "save")!, action: { [weak self] room, value in
            if let button = value as? UIButton {
                self?.previewHandler?(room, button)
            }
        }, identifier: "whiteboard_save")
        RegularFastRoomOverlay.customOptionPanel = {
            var items = RegularFastRoomOverlay.defaultOperationPanelItems
            items.append(saveItem)
            return FastRoomPanel(items: items)
        }
    }
    
    func hideErrorView() {
        errorView.removeFromSuperview()
    }
    
    func showErrorView(error: Error) {
        if errorView.superview == nil {
            view.addSubview(errorView)
            errorView.snp.makeConstraints { make in
                make.edges.equalTo(fastRoom.view.whiteboardView)
            }
        }
        view.bringSubviewToFront(errorView)
        errorViewLabel.text = error.localizedDescription
        errorView.isHidden = false
        errorView.alpha = 0.3
        UIView.animate(withDuration: 0.3) {
            self.errorView.alpha = 1
        }
    }
    
    // MARK: - Lazy
    lazy var errorView: UIView = {
        let view = UIView()
        view.backgroundColor = .whiteBG
        view.addSubview(errorViewLabel)
        errorViewLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addSubview(errorReconnectButton)
        errorReconnectButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(errorViewLabel.snp.bottom).offset(20)
        }
        
        if #available(iOS 13.0, *) {
            let warningImage = UIImage(systemName: "icloud.slash.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            let imageView = UIImageView(image: warningImage)
            view.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(errorViewLabel.snp.top).offset(-20)
            }
        }
        return view
    }()
    
    lazy var errorReconnectButton: FlatGeneralButton = {
        let reconnectButton = FlatGeneralButton(type: .custom)
        reconnectButton.setTitle(NSLocalizedString("Reconnect", comment: ""), for: .normal)
        reconnectButton.addTarget(self, action: #selector(rebindFromError), for: .touchUpInside)
        return reconnectButton
    }()
    
    lazy var errorViewLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        return label
    }()
}

extension FastboardViewController: FastRoomDelegate {
    func fastboardDidJoinRoomSuccess(_ fastboard: FastRoom, room: WhiteRoom) {
        return
    }
    
    func fastboardUserKickedOut(_ fastboard: FastRoom, reason: String) {
        // For this error is caused by server closing, it should be noticed by teacher.
        // showErrorView(error: reason)
    }
    
    func fastboardPhaseDidUpdate(_ fastboard: FastRoom, phase: FastRoomPhase) {
        switch phase {
        case .connecting:
            isRoomJoined.accept(false)
        case .connected:
            return
        case .reconnecting:
            isRoomJoined.accept(false)
        case .disconnecting:
            isRoomJoined.accept(false)
        case .disconnected:
            isRoomJoined.accept(false)
        case .unknown:
            return
        }
    }
    
    func fastboardDidOccurError(_ fastboard: FastRoom, error: FastRoomError) {
        showErrorView(error: error)
    }

    func fastboardDidSetupOverlay(_ fastboard: FastRoom, overlay: FastRoomOverlay?) {
        if let overlay = overlay as? RegularFastRoomOverlay {
            overlay.deleteSelectionPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.operationPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.undoRedoPanel.view?.borderMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            overlay.scenePanel.view?.borderMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

            overlay.invalidAllLayout()
            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalTo(fastboard.view.whiteboardView)
                make.left.equalTo(fastboard.view.whiteboardView)
            }
            overlay.deleteSelectionPanel.view?.snp.makeConstraints({ make in
                make.left.equalTo(overlay.operationPanel.view!)
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
            })
            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(fastboard.view.whiteboardView)
                make.left.equalToSuperview().inset(16)
            }
            overlay.scenePanel.view?.snp.makeConstraints { make in
                make.centerX.equalTo(fastboard.view.whiteboardView)
                make.bottom.equalTo(fastboard.view.whiteboardView)
            }
        }
        if let overlay = overlay as? CompactFastRoomOverlay {
            overlay.operationPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.colorAndStrokePanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.deleteSelectionPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            overlay.undoRedoPanel.view?.direction = .vertical
            overlay.undoRedoPanel.view?.borderMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

            overlay.setPanelItemHide(item: .operationType(.previousPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.pageIndicator)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.nextPage)!, hide: true)
            overlay.setPanelItemHide(item: .operationType(.newPage)!, hide: true)

            overlay.invalidAllLayout()

            overlay.operationPanel.view?.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview()
            }

            overlay.colorAndStrokePanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview()
            }

            overlay.deleteSelectionPanel.view?.snp.makeConstraints { make in
                make.bottom.equalTo(overlay.operationPanel.view!.snp.top).offset(-8)
                make.left.equalToSuperview()
            }

            overlay.undoRedoPanel.view?.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalTo(overlay.operationPanel.view!.snp.bottom).offset(8)
            }
        }
    }
}
