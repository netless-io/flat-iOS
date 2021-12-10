//
//  SidebarViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

@available(iOS 14, *)
class SidebarViewController: UIViewController, UICollectionViewDelegate {
    var controllers: [UIViewController] = [BaseNavigationViewController(rootViewController: HomeViewController()),
                                           BaseNavigationViewController(rootViewController: CloudStorageViewController())]
    
    enum Section {
        case main
    }
    
    class Item: Hashable {
        let title: String
        let imageName: String
        
        private let identifier = UUID()
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func == (lhs: SidebarViewController.Item, rhs: SidebarViewController.Item) -> Bool {
            lhs.identifier == rhs.identifier
        }
        
        internal init(title: String, imageName: String) {
            self.title = title
            self.imageName = imageName
        }
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Flat"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupCollectionView()
        initSupplementary()
    }
    
    func initSupplementary() {
        collectionView.selectItem(at: .init(row: 0, section: 0), animated: false, scrollPosition: .centeredVertically)
        splitViewController?.setViewController(controllers[0], for: .supplementary)
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .blackBG
        collectionView.delegate = self
        
        let reg = UICollectionView.CellRegistration<UICollectionViewListCell, Item>.init { cell, indexPath, itemIdentifier in
            var config = cell.defaultContentConfiguration()
            config.imageProperties.tintColor = .blackBG
            config.text = itemIdentifier.title
            config.image = UIImage(named: itemIdentifier.imageName)
            cell.contentConfiguration = config
            cell.tintColor = .brandColor
        }
        
        datasource = .init(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(using: reg, for: indexPath, item: itemIdentifier)
        })
        
        var initSnapShot = NSDiffableDataSourceSectionSnapshot<Item>()
        initSnapShot.append([.init(title: NSLocalizedString("Home", comment: ""),
                                   imageName: "tab_room"),
                                .init(title: NSLocalizedString("Cloud Storage", comment: ""),
                                      imageName: "tab_cloud_storage")], to: nil)
        
        datasource.apply(initSnapShot, to: .main)
        
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mainSplitViewController?.setViewController(controllers[indexPath.row], for: .supplementary)
        mainSplitViewController?.cleanSecondary()
    }
}
