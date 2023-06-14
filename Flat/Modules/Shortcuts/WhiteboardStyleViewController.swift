//
//  WhiteboardStyleViewController.swift
//  Flat
//
//  Created by xuyunshi on 2023/6/14.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

class WhiteboardStyleViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    let styles = WhiteboardStyle.list
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.setCollectionViewLayout(layout(), animated: true)
    }
    
    func setupViews() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close-bold"), style: .plain, target: self, action: #selector(onClose))
        title = localizeStrings("WhiteboardStyle")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func layout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let margin = CGFloat(20)
        let rowCount = CGFloat(3)
        let itemWidth = (view.bounds.width - (margin * (rowCount + 1))) / rowCount
        layout.itemSize = .init(width: itemWidth, height: itemWidth / 2 + 40)
        layout.sectionInset = .init(inset: margin)
        layout.minimumLineSpacing = margin
        return layout
    }

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout())
        view.delegate = self
        view.dataSource = self
        view.register(WhiteboardStyleCell.self, forCellWithReuseIdentifier: String(describing: WhiteboardStyleCell.self))
        return view
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        styles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WhiteboardStyleCell.self), for: indexPath) as! WhiteboardStyleCell
        let style = styles[indexPath.row]
        cell.update(style: style, selected: Theme.shared.whiteboardStyle.string == style.string)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let style = styles[indexPath.row]
        if style.string != Theme.shared.whiteboardStyle.string {
            Theme.shared.updateUserPreferredStyle(nil, whiteboardStyle: style)
            collectionView.reloadData()
        }
    }
}

class WhiteboardStyleCell: UICollectionViewCell {
    func update(style: WhiteboardStyle, selected: Bool) {
        styleImageView.image = style.image
        selectImageView.image = UIImage(named: selected ? "checklist_selected" : "checklist_normal")
        styleLabel.text = style.localizedString
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = commonBorderWidth
        contentView.layer.borderColor = UIColor.borderColor.cgColor
        
        contentView.addSubview(styleImageView)
        contentView.addSubview(selectImageView)
        contentView.addSubview(styleLabel)
        styleImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
        selectImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(12)
        }
        styleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(40)
            make.centerY.equalTo(selectImageView)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var styleImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var styleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .color(type: .text)
        return label
    }()
    
    lazy var selectImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
}
