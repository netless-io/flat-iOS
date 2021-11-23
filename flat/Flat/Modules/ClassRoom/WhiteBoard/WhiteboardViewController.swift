//
//  WhiteBoardViewController.swift
//  flat
//
//  Created by xuyunshi on 2021/10/15.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import Whiteboard
import RxSwift
import NSObject_Rx
import RxCocoa

class WhiteboardViewController: UIViewController {
    var viewModel: WhiteboardViewModel!
    
    func updateToolsHide(_ hide: Bool) {
        undoRedoOperationBar.isHidden = hide
        operationBar.isHidden = hide
    }
    
    // MARK: - LifeCycle
    init(sdkConfig: WhiteSdkConfiguration,
         roomConfig: WhiteRoomConfig) {
        super.init(nibName: nil, bundle: nil)
        let pannelItems = WhiteboardPannelConfig.defaultPannelItems
        let navi = WhiteboardMenuNavigatorImp(root: self, tapSourceHandler: { [weak self] item -> UIView? in
            guard let self = self else { return nil }
            if let index = self.viewModel.pannelItems.firstIndex(of: item) {
                return self.pannelButtons[index]
            }
            return nil
        }, strokePickerViewController: .init(candicateColors: WhiteboardPannelConfig.defaultColors))
        viewModel = .init(pannelItems: pannelItems,
                          whiteRoomConfig: roomConfig,
                          menuNavigator: navi)
        let whiteSDK = WhiteSDK(whiteBoardView: whiteboardView, config: sdkConfig, commonCallbackDelegate: viewModel)
        viewModel.sdk = whiteSDK
    }
    
    deinit {
        print(self, "deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        let taps = pannelButtons.enumerated().map { [unowned self] index, btn in
            btn.rx.tap.asDriver().map { self.viewModel.pannelItems[index] }
        }
        let output = viewModel.transform(.init(pannelTap: Driver.merge(taps),
                                               undoTap: undoButton.rx.tap.asDriver(),
                                               redoTap: redoButton.rx.tap.asDriver()))
        
        output.join
            .subscribe(onCompleted: { [weak self] in
                self?.setupControlBar()
            })
            .disposed(by: rx.disposeBag)

        output.selectedItem.asDriver(onErrorJustReturn: nil)
            .drive(with: self, onNext: { weakSelf, item in
                weakSelf.selectedPannelItem = item
            })
            .disposed(by: rx.disposeBag)
        
        output.actions
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.subMenuPresent
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.colorAndWidth
            .asDriver(onErrorJustReturn: ((.black, 1)))
            .drive(with: self, onNext: { weakSelf, tuple in
                weakSelf.updateColorPickIndicatorButton(withColor: tuple.0)
            })
            .disposed(by: rx.disposeBag)
        
        output.undo
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        output.redo
            .subscribe()
            .disposed(by: rx.disposeBag)
        
        viewModel.undoEnable
            .asDriver()
            .drive(undoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)

        viewModel.redoEnable
            .asDriver()
            .drive(redoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Private
    func setupViews() {
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func updateColorPickIndicatorButton(withColor color: UIColor) {
        if let index = viewModel.pannelItems.firstIndex(of: .colorAndWidth(displayColor: color)) {
            updateImage(forButton: pannelButtons[index], item: .colorAndWidth(displayColor: color))
            print("update color button with \(color)")
        }
    }
    
    // MARK: - Private
    func setupControlBar() {
        view.addSubview(operationBar)
        operationBar.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        view.addSubview(undoRedoOperationBar)
        undoRedoOperationBar.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(86)
        }
        
        syncSelectedPannelItem()
    }
    
    // MARK: - Lazy
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        // handle keyboard by IQKeyboardManager
        view.disableKeyboardHandler = true
        return view
    }()
    
    lazy var undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "whiteboard_undo"), for: .normal)
        return button
    }()
    
    lazy var redoButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "whiteboard_redo"), for: .normal)
        return button
    }()
    
    lazy var pannelButtons: [UIButton] = {
        let btns = viewModel.pannelItems.enumerated().map { index, item -> UIButton in
            let btn: UIButton
            if item.hasSubMenu {
                btn = IndicatorMoreButton(type: .custom)
                (btn as? IndicatorMoreButton)?.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
            } else {
                btn = UIButton(type: .custom)
            }
            updateImage(forButton: btn, item: item)
            btn.tag = index
            return btn
        }
        return btns
    }()
    
    func updateImage(forButton button: UIButton, item: WhitePannelItem) {
        button.setImage(item.image, for: .normal)
        button.setImage(item.selectedImage, for: .selected)
    }
    
    func syncSelectedPannelItem() {
        viewModel.pannelItems.enumerated().forEach { index, item in
            let btn = pannelButtons[index]
            btn.isSelected = item == selectedPannelItem
        }

        if let selected = selectedPannelItem, let buttonIndex = viewModel.pannelItems.firstIndex(of: selected) {
            let btn = pannelButtons[buttonIndex]
            updateImage(forButton: btn, item: selected)
            // TODO: Move this to viewmodel
            viewModel.pannelItems[buttonIndex] = selected
        }
    }
    
    lazy var selectedPannelItem: WhitePannelItem? = nil {
        didSet {
            syncSelectedPannelItem()
        }
    }
    
    lazy var undoRedoOperationBar: RoomControlBar = {
        return RoomControlBar(direction: .horizontal,
                              borderMask: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                              buttons: [undoButton, redoButton])
    }()
    
    lazy var operationBar: RoomControlBar = {
        return RoomControlBar(direction: .vertical,
                              borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner],
                              buttons: pannelButtons)
    }()
}
