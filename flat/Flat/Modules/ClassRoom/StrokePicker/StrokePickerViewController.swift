//
//  StrokePickerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import RxSwift
import RxRelay

class StrokePickerViewController: PopOverDismissDetectableViewController {
    let selectedColor: BehaviorRelay<UIColor>
    let lineWidth: BehaviorRelay<Float>
    
    var colors: [UIColor]
    let itemSize = CGSize(width: 30, height: 30)
    let collectionViewEdgeInset = UIEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)
    let itemSpacing: CGFloat = 10
    let sliderSpace: CGFloat = 44
    let pickerCellIdentifier = "pickerCellIdentifier"
    
    func updateCurrentColor(_ currentColor: UIColor, lineWidth: Float) {
        self.lineWidth.accept(lineWidth)
        if !self.colors.contains(currentColor) {
            colors.append(currentColor)
        }
        self.selectedColor.accept(currentColor)
        slider.value = lineWidth
    }
    
    // MARK: - LifeCycle
    init(minStrokeWidth: Float = 1,
         maxStrokeWidth: Float = 20,
         candicateColors: [UIColor]
    ) {
        self.lineWidth = .init(value: minStrokeWidth)
        self.selectedColor = .init(value: candicateColors[0])
        self.colors = candicateColors
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        self.slider.minimumValue = minStrokeWidth
        self.slider.maximumValue = maxStrokeWidth
        self.slider.value = minStrokeWidth
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPreferredContentSize()
        bind()
    }

    // MARK: - Private
    func bind() {
        let startIndex = selectedColor
            .take(1)
            .map {
                Int(self.colors.firstIndex(of: $0)!)
            }
        
        let selectIndex = collectionView.rx.itemSelected.map { $0.row }
        Observable.of(startIndex, selectIndex)
            .merge()
            .map { [weak self] index -> [(UIColor, Bool)] in
                guard let self = self else { return [] }
                return self.colors.enumerated().map {
                    ($0.element, $0.offset == index)
                }
            }
            .asDriver(onErrorJustReturn: [])
            .drive(collectionView.rx.items(cellIdentifier: pickerCellIdentifier, cellType: StrokeColorCollectionViewCell.self)) { index, item, cell in
                cell.update(color: item.0, selected: item.1)
            }
            .disposed(by: rx.disposeBag)
        
        selectIndex
            .map { [weak self] index -> UIColor in
                self?.colors[index] ?? .black
            }
            .asDriver(onErrorJustReturn: .black)
            .drive(selectedColor)
            .disposed(by: rx.disposeBag)
        
        slider.rx.value
            .asDriver()
            .drive(lineWidth)
            .disposed(by: rx.disposeBag)
    }
    
    func setupPreferredContentSize() {
        let itemPerRow: CGFloat = 4
        let itemWidthTotal = (itemPerRow * itemSize.width) + ((itemPerRow - 1) * itemSpacing)
        let rows = ceil(CGFloat(colors.count) / itemPerRow)
        let itemHeightTotal = (rows * itemSize.height) + ((rows - 1) * itemSpacing)
        preferredContentSize = .init(width: collectionViewEdgeInset.left + collectionViewEdgeInset.right + itemWidthTotal,
                                     height: collectionViewEdgeInset.top + collectionViewEdgeInset.bottom + itemHeightTotal + sliderSpace + view.safeAreaInsets.top)
    }
    
    func setupViews() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        }
        view.addSubview(slider)
        slider.snp.makeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(collectionViewEdgeInset.left)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(sliderSpace)
        }
        
        let line = UIView()
        line.backgroundColor = .borderColor
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(collectionViewEdgeInset.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.top.equalTo(slider.snp.bottom)
        }
    }
    
    // MARK: - Lazy
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionInset = UIEdgeInsets(top: collectionViewEdgeInset.top + sliderSpace, left: collectionViewEdgeInset.left, bottom: collectionViewEdgeInset.bottom, right: collectionViewEdgeInset.right)
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.register(StrokeColorCollectionViewCell.self, forCellWithReuseIdentifier: pickerCellIdentifier)
        return view
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        return slider
    }()
}
