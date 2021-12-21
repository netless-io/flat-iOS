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
    
    func updatePageOperationHide(_ hide: Bool) {
        sceneOperationBar.isHidden = hide
    }
    
    func updateToolsHide(_ hide: Bool) {
        undoRedoOperationBar.isHidden = hide
        operationBars.forEach { $0.isHidden = hide }
    }
    
    // MARK: - LifeCycle
    init(sdkConfig: WhiteSdkConfiguration,
         roomConfig: WhiteRoomConfig) {
        super.init(nibName: nil, bundle: nil)
        let panelItems = traitCollection.hasCompact ? WhiteboardPanelConfig.defaultCompactPanelItems : WhiteboardPanelConfig.defaultPanelItems
        let navi = WhiteboardMenuNavigatorImp(root: self, clickToDismiss: traitCollection.hasCompact, tapSourceHandler: { [weak self] item -> UIView? in
            guard let self = self else { return nil }
            if let indexPath = self.viewModel.getPanelItem(forItem: item)?.indexPath {
                return self.panelButtons[indexPath.section][indexPath.row]
            }
            return nil
        })
        viewModel = .init(shouldNarrowPanelItems: traitCollection.hasCompact,
                          panelItems: panelItems,
                          whiteRoomConfig: roomConfig,
                          menuNavigator: navi)
        let whiteSDK = WhiteSDK(whiteBoardView: whiteboardView,
                                config: sdkConfig,
                                commonCallbackDelegate: viewModel)
        viewModel.sdk = whiteSDK
    }
    
    deinit {
        print(self, "deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        whiteboardView.backgroundColor = .whiteBG
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }
    
    // MARK: - Private
    func setupViews() {
        view.addSubview(whiteboardView)
        whiteboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func rebindFromError() {
        hideErrorView()
        var temp = self
        temp.rx.disposeBag = DisposeBag()
        bind()
    }
    
    func bind() {
        let taps = panelButtons.flatMap{ $0 }.map { [unowned self] btn -> Driver<WhitePanelItem> in
            let indexPath = self.getPanelButtonIndexPath(fromTag: btn.tag)
            return btn.rx.tap.asDriver().map { self.viewModel.panelItems[indexPath.section][indexPath.row] }
        }
        
        let output = viewModel.transform(.init(panelTap: Driver.merge(taps),
                                               undoTap: undoButton.rx.tap.asDriver(),
                                               redoTap: redoButton.rx.tap.asDriver()))
        
        showActivityIndicator()
        output.join
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self) { weakSelf, room in
                weakSelf.stopActivityIndicator()
                weakSelf.hideErrorView()
                weakSelf.setupControlBar()
            } onError: { weakSelf, error in
                weakSelf.showErrorView(error: error)
            } onCompleted: { weakSelf in
                weakSelf.stopActivityIndicator()
            } onDisposed: { weakSelf in
                weakSelf.stopActivityIndicator()
            }
            .disposed(by: rx.disposeBag)
        output.selectedItem.asDriver(onErrorJustReturn: nil)
            .drive(with: self, onNext: { weakSelf, item in
                weakSelf.selectedPanelItem = item
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
        
        let sceneOutput = viewModel.transformSceneInput(.init(previousTap: previousSceneButton.rx.tap.asDriver(),
                                                              nextTap: nextSceneButton.rx.tap.asDriver(),
                                                              newTap: newSceneButton.rx.tap.asDriver()))
        
        sceneOutput.taps
            .drive()
            .disposed(by: rx.disposeBag)
        sceneOutput.nextEnable
            .drive(nextSceneButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        sceneOutput.previousEnable
            .drive(previousSceneButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        sceneOutput.sceneTitle
            .drive(sceneLabel.rx.title(for: .normal))
            .disposed(by: rx.disposeBag)
        
        viewModel.undoEnable
            .asDriver()
            .drive(undoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.redoEnable
            .asDriver()
            .drive(redoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.errorSignal
            .subscribe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { weakSelf, error in
                weakSelf.showErrorView(error: error)
            })
            .disposed(by: rx.disposeBag)
    }
    
    func updateColorPickIndicatorButton(withColor color: UIColor) {
        guard let indexPath = viewModel.getPanelItem(forItem: .color(displayColor: color))?.indexPath else { return }
        let button = panelButtons[indexPath.section][indexPath.row]
        updateImage(forButton: button, item: .color(displayColor: color))
    }
    
    // MARK: - Private
    func setupControlBar() {
        if traitCollection.hasCompact {
            var itemViews: [UIView] = []
            itemViews.append(undoRedoOperationBar)
            itemViews.append(contentsOf: operationBars)
            let stackView = UIStackView(arrangedSubviews: itemViews)
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.spacing = 20
            view.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.left.greaterThanOrEqualToSuperview().priority(.high)
                make.left.equalTo(view.safeAreaLayoutGuide)
                let off = globalRoomControlBarItemWidth * 2 + stackView.spacing / 2
                make.top.equalTo(self.view.snp.centerY).offset(-off)
            }
        } else {
            operationBars.reversed().enumerated().forEach { index, bar in
                view.addSubview(bar)
                if index == 0 {
                    bar.snp.makeConstraints { make in
                        make.centerY.equalToSuperview()
                        make.left.greaterThanOrEqualToSuperview().priority(.high)
                        make.left.equalTo(view.safeAreaLayoutGuide)
                    }
                } else {
                    let lastBar = operationBars.reversed()[index - 1]
                    bar.snp.makeConstraints { make in
                        make.left.equalTo(lastBar)
                        make.bottom.equalTo(lastBar.snp.top).offset(-20)
                    }
                }
            }
            view.addSubview(undoRedoOperationBar)
            undoRedoOperationBar.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(86)
            }
            
            view.addSubview(sceneOperationBar)
            sceneOperationBar.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(86)
            }
        }
        
        syncSelectedPanelItem()
    }
    
    func hideErrorView() {
        errorView.removeFromSuperview()
    }
    
    func showErrorView(error: Error) {
        if errorView.superview == nil {
            view.addSubview(errorView)
            errorView.snp.makeConstraints { make in
                make.edges.equalTo(whiteboardView)
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
    
    lazy var whiteboardView: WhiteBoardView = {
        let view = WhiteBoardView()
        // handle keyboard by IQKeyboardManager
        view.disableKeyboardHandler = true
        view.backgroundColor = .whiteBG
        view.navigationDelegate = self
        return view
    }()
    
    lazy var sceneLabel: UIButton = {
        let button = UIButton(type: .custom)
        button.isUserInteractionEnabled = false
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.text, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.minimumScaleFactor = 0.5
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        return button
    }()
    
    lazy var nextSceneButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "scene_next"), for: .normal)
        return button
    }()
    
    lazy var previousSceneButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "scene_previous"), for: .normal)
        return button
    }()
    
    lazy var newSceneButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .controlNormal
        button.setImage(UIImage(named: "scene_new"), for: .normal)
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
    
    func getPanelButtonIndexPath(fromTag tag: Int) -> IndexPath {
        let section = tag / 1000 - 1
        let row = tag % 10
        return .init(row: row, section: section)
    }
    
    func panelButtonTag(indexPath: IndexPath) -> Int {
        return (indexPath.section + 1) * 1000 + indexPath.row
    }
    
    lazy var panelButtons: [[UIButton]] = {
        viewModel.panelItems.enumerated().map { section, items -> [UIButton] in
            let btns = items.enumerated().map { row, item -> UIButton in
                let btn: UIButton
                if item.hasSubMenu {
                    btn = IndicatorMoreButton(type: .custom)
                    (btn as? IndicatorMoreButton)?.indicatorInset = .init(top: 5, left: 0, bottom: 0, right: 5)
                } else {
                    btn = UIButton(type: .custom)
                }
                updateImage(forButton: btn, item: item)
                btn.tag = panelButtonTag(indexPath: IndexPath(row: row, section: section))
                return btn
            }
            return btns
        }
    }()
    
    func updateImage(forButton button: UIButton, item: WhitePanelItem) {
        button.setImage(item.image, for: .normal)
        button.setImage(item.selectedImage, for: .selected)
        button.traitCollectionUpdateHandler = { [weak button] _ in
            button?.setImage(item.image, for: .normal)
            button?.setImage(item.selectedImage, for: .selected)
        }
    }
    
    func syncSelectedPanelItem() {
        viewModel.panelItemsWithDisplayInfo.enumerated().forEach { section, items in
            items.enumerated().forEach { row, value in
                let item = value.item
                let hide = value.hide
                let selected = item == selectedPanelItem?.item
                let btn = panelButtons[section][row]
                
                btn.isSelected = selected
                sceneOperationBar.updateButtonHide(btn, hide: hide)
            }
        }
        
        if let selected = selectedPanelItem {
            let btn = panelButtons[selected.indexPath.section][selected.indexPath.row]
            updateImage(forButton: btn, item: selected.item)
        }
    }
    
    lazy var selectedPanelItem: IndexedWhiteboardPanelItem? = nil {
        didSet {
            syncSelectedPanelItem()
        }
    }
    
    lazy var sceneOperationBar: RoomControlBar = {
        let bar = RoomControlBar(direction: .horizontal,
                                 borderMask: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                                 buttons: [newSceneButton, previousSceneButton, sceneLabel, nextSceneButton])
        return bar
    }()
    
    lazy var undoRedoOperationBar: RoomControlBar = {
        if traitCollection.hasCompact {
            return RoomControlBar(direction: .vertical,
                                  borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner],
                                  buttons: [undoButton, redoButton])
        } else {
            return RoomControlBar(direction: .horizontal,
                                  borderMask: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                                  buttons: [undoButton, redoButton])
        }
    }()
    
    lazy var operationBars: [RoomControlBar] = {
        return panelButtons.map {
            return RoomControlBar(direction: .vertical,
                           borderMask: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner],
                           buttons: $0)
        }
    }()
}

extension WhiteboardViewController: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        UIApplication.shared.topViewController?.showAlertWith(message: "whiteboard view terminate, please rejoin the room again")
    }
}
