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
    let appliancePickerCellIdentifier = "appliancePickerCellIdentifier"
    let newOperation: PublishRelay<WhiteboardPannelOperation> = .init()
    
    let operations: BehaviorRelay<[WhiteboardPannelOperation]>
    let selectedIndex: BehaviorRelay<Int?>
    let itemSize = CGSize(width: 40, height: 40)
    
    init(operations: [WhiteboardPannelOperation],
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
        view.backgroundColor = .white
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
        .drive(collectionView.rx.items(cellIdentifier: appliancePickerCellIdentifier, cellType: AppliancePickerCollectionViewCell.self)) {  index, item, cell in
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
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] row in
                guard let operaion = self?.operations.value[row] else { return }
                self?.newOperation.accept(operaion)
                if case .clean = operaion {
                } else {
                    self?.selectedIndex.accept(row)
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
