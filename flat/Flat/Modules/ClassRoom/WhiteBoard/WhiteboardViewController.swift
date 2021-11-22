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

struct WhiteboardToolNavigator {
    weak var appliancePickerButton: UIButton?
    weak var strokePickerButton: UIButton?
    weak var root: UIViewController?
    
    let appliancePickerViewController = AppliancePickerViewController.init(operations: WhiteboardPannel.operations, selectedIndex: nil)
    let strokePickerViewController = StrokePickerViewController()
    
    func presentColorPicker(withCurrentColor color: UIColor, currentWidth: Float) -> (Driver<(UIColor, Float)>){
        guard let root = root else {
            return .just((.black, 0))
        }
        strokePickerViewController.updateCurrentColor(color, lineWidth: currentWidth)
        root.popoverViewController(viewController: strokePickerViewController, fromSource: strokePickerButton)
        let out = Observable.combineLatest(strokePickerViewController.selectedColor,
                                 strokePickerViewController.lineWidth)
            .asDriver(onErrorJustReturn: (.black, 0))
        return out
    }
    
    func presentAppliancePicker(withSelectedAppliance appliance: WhiteApplianceNameKey) -> Driver<WhiteBoardOperation> {
        guard let root = root else {
            return .just(.updateAppliance(name: .ApplianceArrow))
        }
        let index = appliancePickerViewController.operations.value.firstIndex(where: { op in
            if case .updateAppliance(name: let name) = op {
                return name == appliance
            }
            return false
        })
        appliancePickerViewController.selectedIndex.accept(index)
        root.popoverViewController(viewController: appliancePickerViewController, fromSource: appliancePickerButton)
        return appliancePickerViewController.newOperation.asDriver(onErrorJustReturn: .clean)
    }
}

class WhiteboardViewController: UIViewController {
    var viewModel: WhiteboardViewModel!
    
    // MARK: - LifeCycle
    init(sdkConfig: WhiteSdkConfiguration,
         roomConfig: WhiteRoomConfig) {
        super.init(nibName: nil, bundle: nil)
        let navi = WhiteboardToolNavigator(appliancePickerButton: applicanceIndicatorButton,
                                           strokePickerButton: colorPickIndicatorButton,
                                           root: self)
        viewModel = .init(whiteRoomConfig: roomConfig,
                          whiteboardToolNavigator: navi)
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
        
        let output = viewModel.transformInput(trigger: .just(()),
                                              undoTap: undoButton.rx.tap.asDriver(),
                                              redoTap: redoButton.rx.tap.asDriver(),
                                              applianceTap: applicanceIndicatorButton.rx.tap.asDriver(),
                                              strokeTap: colorPickIndicatorButton.rx.tap.asDriver())
        
        output.join
            .subscribe(onCompleted: { [weak self] in
                self?.setupControlBar()
            })
            .disposed(by: rx.disposeBag)
        
        output.taps
            .drive()
            .disposed(by: rx.disposeBag)
        
        output.appliance
            .drive(onNext: { [weak self] in
                self?.applicanceIndicatorButton.updateAppliance($0)
            })
            .disposed(by: rx.disposeBag)
        
        output.strokeValue
            .drive()
            .disposed(by: rx.disposeBag)
        
        viewModel.strokeColor
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] color in
                self?.updateColorPickIndicatorButton(withColor: color)
            }
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
        let normalImage = UIImage.pickerItemImage(withColor: color, size: .init(width: 18, height: 18), radius: 9)
        colorPickIndicatorButton.setImage(normalImage, for: .normal)
        
        if let normalImage = normalImage {
            let bg = UIImage.pointWith(color: .controlSelectedBG, size: .init(width: 30, height: 30), radius: 5)
            let selectedImage = bg.compose(normalImage)
            colorPickIndicatorButton.setImage(selectedImage, for: .selected)
        }
    }
    
    // MARK: - Private
    func setupControlBar() {
        view.addSubview(toolStackView)
        toolStackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Lazy
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        // handle keyboard by IQKeyboardManager
        view.disableKeyboardHandler = true
        return view
    }()
    
    lazy var colorPickIndicatorButton: UIButton = {
        let button = IndicatorMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        return button
    }()
    
    lazy var applicanceIndicatorButton: IndicatorMoreButton = {
        let button = IndicatorMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        button.updateAppliance(.ApplianceArrow)
        button.isSelected = true
        return button
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
    
    lazy var toolStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [undoRedoOperationBar, operationBar])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        return stackView
    }()
    
    lazy var undoRedoOperationBar: RoomControlBar = {
        return RoomControlBar(direction: .vertical, borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner], buttons: [undoButton, redoButton])
    }()
    
    lazy var operationBar: RoomControlBar = {
        return RoomControlBar(direction: .vertical,
                              borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner],
                              buttons: [colorPickIndicatorButton, applicanceIndicatorButton])
    }()
}
