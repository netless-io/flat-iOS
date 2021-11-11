//
//  StrokePickerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit
import SwiftUI

protocol StrokePickerViewControllerDelegate: AnyObject {
    func strokePickerViewControllerDidUpdateSelectedColor(_ controller: StrokePickerViewController, selectedColor: UIColor)
    
    func strokePickerViewControllerDidUpdateStrokeLineWidth(_ controller: StrokePickerViewController, lineWidth: Float)
}

class StrokePickerViewController: PopOverDismissDetectableViewController {
    var selectedColor: UIColor = .white {
        didSet {
            syncSelectedColor()
            delegate?.strokePickerViewControllerDidUpdateSelectedColor(self, selectedColor: selectedColor)
        }
    }
    var lineWidth: Float {
        didSet {
            delegate?.strokePickerViewControllerDidUpdateStrokeLineWidth(self, lineWidth: lineWidth)
        }
    }
    let colors: [UIColor]
    let maxStrokeWidth: Float
    let minStrokeWidth: Float
    weak var delegate: StrokePickerViewControllerDelegate?
    
    let pickerCellIdentifier = "pickerCellIdentifier"
    
    let itemSize = CGSize(width: 30, height: 30)
    let collectionViewEdgeInset = UIEdgeInsets(top: 10, left: 5, bottom: 5, right: 5)
    let itemSpacing: CGFloat = 10
    let sliderSpace: CGFloat = 44
    
    // MARK: - LifeCycle
    init(selectedColor: UIColor,
         lineWidth: Float,
         minStrokeWidth: Float = 1,
         maxStrokeWidth: Float = 20,
         candicateColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen,
                                       .systemTeal, .systemBlue, .init(hexString: "#6236FF"), .systemPurple,
                                       .init(hexString: "#BCC0C6"), .systemGray, .black, .white]
         
    ) {
        self.lineWidth = lineWidth
        var candicateColors: [UIColor] = candicateColors
        self.selectedColor = selectedColor
        if !candicateColors.contains(selectedColor) {
            candicateColors.append(selectedColor)
        }
        self.minStrokeWidth = minStrokeWidth
        self.maxStrokeWidth = maxStrokeWidth
        self.colors = candicateColors
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        syncSelectedColor()
        setupPreferredContentSize()
    }

    // MARK: - Private
    func syncSelectedColor() {
        slider.tintColor = selectedColor
        collectionView.reloadData()
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
    
    // MARK: - Action
    @objc func onSliderValueUpdate(_ sender: UISlider) {
        print(sender.value)
        lineWidth = sender.value
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
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = minStrokeWidth
        slider.maximumValue = maxStrokeWidth
        slider.value = lineWidth
        slider.addTarget(self, action: #selector(onSliderValueUpdate(_:)), for: .valueChanged)
        return slider
    }()
}

extension StrokePickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pickerCellIdentifier, for: indexPath) as! StrokeColorCollectionViewCell
        let color = colors[indexPath.row]
        cell.update(color: color, selected: color == selectedColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedColor = colors[indexPath.row]
    }
}
