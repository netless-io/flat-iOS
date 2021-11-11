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
    let viewModel: WhiteboardViewModel
    
    // MARK: - LifeCycle
    init(uuid: String,
         token: String,
         userName: String?) {
        viewModel = .init(uuid: uuid, token: token, userName: userName)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        viewModel.setupWith(whiteboardView)
        
        viewModel.joinRoom().subscribe(onCompleted:  { [weak self] in
            self?.setupControlBar()
        }).disposed(by: rx.disposeBag)
        
        viewModel.appliance
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] i in
                self?.applicanceIndicatorButton.updateAppliance(i)
            }
            .disposed(by: rx.disposeBag)
        
        viewModel.strokeColor
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] color in
                self?.updateColorPickIndicatorButton(withColor: color)
            }
            .disposed(by: rx.disposeBag)
        
        
        viewModel.redoEnableCount
            .map { $0 > 0 }
            .bind(to: redoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        viewModel.undoEnableCount
            .map { $0 > 0 }
            .bind(to: undoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        undoButton.rx.tap
            .subscribe { [weak self] _ in
                self?.viewModel.undo()
            }
            .disposed(by: rx.disposeBag)
        
        redoButton.rx.tap
            .subscribe { [weak self] _ in
                self?.viewModel.redo()
            }
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Private
    func updateColorPickIndicatorButton(withColor color: UIColor) {
        let normalImage = UIImage.pickerItemImage(withColor: color, size: .init(width: 18, height: 18), radius: 9)
        colorPickIndicatorButton.setImage(normalImage, for: .normal)
        
        if let normalImage = normalImage {
            let bg = UIImage.pointWith(color: .controlSelectedBG, size: .init(width: 30, height: 30), radius: 5)
            let selectedImage = bg.compose(normalImage)
            colorPickIndicatorButton.setImage(selectedImage, for: .selected)
        }
    }
    
    // MARK: - Action
    @objc func onClickMoreAppliance(_ sender: UIButton) {
        popoverViewController(viewController: appliancePickerController, fromSource: sender, permittedArrowDirections: .left)
    }
    
    @objc func onClickColor(_ sender: UIButton) {
        sender.isSelected = true
        popoverViewController(viewController: colorPickerController, fromSource: sender, permittedArrowDirections: .left)
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
    lazy var colorPickerController: StrokePickerViewController = {
        let color = try! viewModel.strokeColor.value()
        let width = try! viewModel.strokeWidth.value()
        let vc = StrokePickerViewController(selectedColor: color,
                                            lineWidth: width)
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.colorPickIndicatorButton.isSelected = false
            let lineWidth = self.colorPickerController.lineWidth
            let selectedColor = self.colorPickerController.selectedColor
            self.viewModel.update(stokeWidth: lineWidth,
                                  stokeColor: selectedColor,
                                  appliance: nil)
        }
        vc.delegate = self
        return vc
    }()
    
    lazy var appliancePickerController: AppliancePickerViewController = {
        let current = viewModel.room.memberState.currentApplianceName
        let images = viewModel.panelOperations.map { $0.buttonImage! }
        let selectedIndex = viewModel.panelOperations.firstIndex(where: {
            if case .updateAppliance(name: let key) = $0, key == current {
                return true
            }
            return false
        })
        let vc = AppliancePickerViewController(applianceImages: images, selectedIndex: selectedIndex)
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            if let index = self.appliancePickerController.selectedIndex {
                self.viewModel.pickOperation(index: index)
            }
        }
        vc.delegate = self
        return vc
    }()
    
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        // handle keyboard by IQKeyboardManager
        view.disableKeyboardHandler = true
        return view
    }()
    
    lazy var colorPickIndicatorButton: UIButton = {
        let button = IndicatorMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(onClickColor(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var applicanceIndicatorButton: IndicatorMoreButton = {
        let button = IndicatorMoreButton(type: .custom)
        button.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
        button.updateAppliance(.ApplianceArrow)
        button.isSelected = true
        button.addTarget(self, action: #selector(onClickMoreAppliance(_:)), for: .touchUpInside)
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

extension WhiteboardViewController: StrokePickerViewControllerDelegate {
    func strokePickerViewControllerDidUpdateSelectedColor(_ controller: StrokePickerViewController, selectedColor: UIColor) {
        viewModel.update(stokeWidth: nil,
                         stokeColor: selectedColor,
                         appliance: nil)
    }
    
    func strokePickerViewControllerDidUpdateStrokeLineWidth(_ controller: StrokePickerViewController, lineWidth: Float) {
    }
}

extension WhiteboardViewController: AppliancePickerViewControllerDelegate {
    func appliancePickerViewControllerDidSelectAppliance(_ controller: AppliancePickerViewController, index: Int) {
        viewModel.pickOperation(index: index)
    }
    
    func appliancePickerViewControllerShouldSelectAppliance(_ controller: AppliancePickerViewController, index: Int) -> Bool {
        viewModel.couldPickOperation(index: index)
    }
}
