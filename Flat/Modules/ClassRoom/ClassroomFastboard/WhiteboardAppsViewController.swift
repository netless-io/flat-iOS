//
//  WhiteboardAppsViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/5.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import Whiteboard

class WhiteboardAppsViewController: UIViewController {
    struct WhiteboardAppItem {
        let title: String
        let imageName: String
    }

    let items: [WhiteboardAppItem] = [
        .init(title: localizeStrings("whiteboard_save_annotation"), imageName: "whiteboard_save_annotation"),
    ]

    var room: WhiteRoom?
    weak var clickSource: UIButton?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let rows = ceil(CGFloat(items.count) / numberPerRow)
        preferredContentSize = .init(width: layout.itemSize.width * numberPerRow + layout.sectionInset.left + layout.sectionInset.right,
                                     height: layout.itemSize.height * rows + layout.sectionInset.top + layout.sectionInset.bottom)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Private

    func setupViews() {
        view.backgroundColor = .classroomChildBG
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Lazy

    let numberPerRow: CGFloat = 3

    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 120, height: 66 + 8)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .init(inset: 16)
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .classroomChildBG
        view.register(WhiteboardAppsCell.self, forCellWithReuseIdentifier: String(describing: WhiteboardAppsCell.self))
        view.delegate = self
        view.dataSource = self
        return view
    }()
}

extension WhiteboardAppsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int { 1 }
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: WhiteboardAppsCell.self), for: indexPath) as! WhiteboardAppsCell
        let item = items[indexPath.row]
        cell.appTitleLabel.text = item.title
        cell.appIconView.image = UIImage(named: item.imageName)
        cell.appIconView.backgroundColor = UIColor(hexString: "#00C35A")
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        guard let room = room, let parent = presentingViewController, let source = clickSource else { return }
        let vc = WhiteboardScenesListViewController(room: room)
        dismiss(animated: true) {
            parent.popoverViewController(viewController: vc, fromSource: source)
        }
    }
}
