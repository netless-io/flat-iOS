//
//  AppliancePickerViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/20.
//  Copyright © 2021 agora.io. All rights reserved.
//


import UIKit

protocol AppliancePickerViewControllerDelegate: AnyObject {
    func appliancePickerViewControllerShouldSelectAppliance(_ controller: AppliancePickerViewController, index: Int) -> Bool
    
    func appliancePickerViewControllerDidSelectAppliance(_ controller: AppliancePickerViewController, index: Int)
}

class AppliancePickerViewController: PopOverDismissDetectableViewController {
    weak var delegate: AppliancePickerViewControllerDelegate?

    let appliancePickerCellIdentifier = "appliancePickerCellIdentifier"
    var selectedIndex: Int? {
        didSet {
            if let selectedIndex = selectedIndex {
                delegate?.appliancePickerViewControllerDidSelectAppliance(self, index: selectedIndex)
            }
            collectionView.reloadData()
        }
    }
    let applianceImages: [UIImage]
    
    init(applianceImages: [UIImage],
         selectedIndex: Int?) {
        self.applianceImages = applianceImages
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPreferredContentSize()
    }
    
    let itemSize = CGSize(width: 40, height: 40)
    
    // MARK: - Private
    func setupViews() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func setupPreferredContentSize() {
        let itemPerRow: CGFloat = 5
        let rows = ceil(CGFloat(applianceImages.count) / itemPerRow)
        preferredContentSize = itemSize.applying(.init(scaleX: itemPerRow, y: rows))
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
        view.delegate = self
        view.dataSource = self
        view.register(AppliancePickerCollectionViewCell.self, forCellWithReuseIdentifier: appliancePickerCellIdentifier)
        return view
    }()
}

extension AppliancePickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        applianceImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: appliancePickerCellIdentifier, for: indexPath) as! AppliancePickerCollectionViewCell
        cell.imageView.image = applianceImages[indexPath.row]
        cell.imageView.tintColor = indexPath.row == selectedIndex ? .controlSelected : .controlNormal
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let shouldSelect = delegate?.appliancePickerViewControllerShouldSelectAppliance(self, index: indexPath.row),
              shouldSelect else {
                  let cell = (collectionView.cellForItem(at: indexPath) as? AppliancePickerCollectionViewCell)
                  cell?.imageView.tintColor = .controlSelected
                  UIView.animate(withDuration: 0.3) {
                      cell?.imageView.tintColor = .controlNormal
                  }
                  return
              }
        selectedIndex = indexPath.row
    }
}
