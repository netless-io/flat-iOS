//
//  AppliancePickerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift
import RxRelay
import Whiteboard

class AppliancePickerViewController: PopOverDismissDetectableViewController {
    var clickToDismiss = false
    let appliancePickerCellIdentifier = "appliancePickerCellIdentifier"
    let newOperation: PublishRelay<WhiteboardPanelOperation> = .init()
    
    let operations: BehaviorRelay<[WhiteboardPanelOperation]>
    let selectedIndex: BehaviorRelay<Int?>
    let itemSize = CGSize(width: 40, height: 40)
    
    init(operations: [WhiteboardPanelOperation],
         selectedIndex: Int?) {
        self.operations = .init(value: operations)
        self.selectedIndex = .init(value: selectedIndex)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .whiteBG
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func bind() {
        let operationsAndSelectedIndex = Observable.combineLatest(operations, selectedIndex)
        
        operationsAndSelectedIndex.map { ops, si in
            return ops.enumerated().map {
                ($0.element, $0.offset == si)
            }
        }
        .asDriver(onErrorJustReturn: ([]))
        .do(onNext: { [unowned self] _ in
            if self.clickToDismiss {
                if let vc = self.presentingViewController {
                    vc.dismiss(animated: true, completion: nil)
                }
            }
        })
        .drive(
            collectionView.rx.items(cellIdentifier: appliancePickerCellIdentifier, cellType: AppliancePickerCollectionViewCell.self)) {  index, item, cell in
                cell.imageView.image = item.1 ? item.0.selectedImage : item.0.image
        }
        .disposed(by: rx.disposeBag)
        
        let itemPerRow: CGFloat = 5
        let rows = operations.map { ceil(CGFloat($0.count) / itemPerRow) }
        rows.asDriver(onErrorJustReturn: 44)
            .drive(onNext: { [weak self] r in
                guard let self = self else { return }
                self.preferredContentSize = self.itemSize.applying(.init(scaleX: itemPerRow, y: r))
            })
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.itemSelected
            .map { $0.row }
            .subscribe(onNext: { [weak self] row in
                guard let operation = self?.operations.value[row] else { return }
                self?.newOperation.accept(operation)
                if operation.selectable {
                    self?.selectedIndex.accept(row)
                } else {
                    if let cell = self?.collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? AppliancePickerCollectionViewCell {
                        cell.triggerActivityAnimation()
                    }
                }
            })
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: - Lazy
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(AppliancePickerCollectionViewCell.self, forCellWithReuseIdentifier: appliancePickerCellIdentifier)
        return view
    }()
}
