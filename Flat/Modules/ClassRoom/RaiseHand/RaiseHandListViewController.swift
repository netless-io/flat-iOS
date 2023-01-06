//
//  RaiseHandListViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/12/29.
//  Copyright © 2022 agora.io. All rights reserved.
//

import RxRelay
import RxSwift
import UIKit
import DZNEmptyDataSet

class RaiseHandListViewController: UIViewController {
    let cellIdentifier = "cellIdentifier"
    
    let acceptRaiseHandPublisher: PublishRelay<RoomUser> = .init()
    let checkAllPublisher: PublishRelay<Void> = .init()
    
    var raiseHandUsers: Observable<[RoomUser]>? {
        didSet {
            guard let raiseHandUsers else { return }
            let userDriver = raiseHandUsers
                .asDriver(onErrorJustReturn: [])
            
            userDriver
                .drive(tableView.rx
                    .items(cellIdentifier: cellIdentifier, cellType: RaiseHandTableViewCell.self)) {
                        [weak self] _, item, cell in
                        self?.config(cell: cell, item: item)
                }
                .disposed(by: rx.disposeBag)
            
            userDriver
                .map { $0.count < 2 }
                .drive(bottomView.rx.isHidden)
                .disposed(by: rx.disposeBag)
        }
    }
    
    // MARK: - LifeCycle

    init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = .init(width: 200, height: 336)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Reload to contentSize fit
        tableView.reloadEmptyDataSet()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Action

    @objc func onClickViewAll() {
        checkAllPublisher.accept(())
    }
    
    // MARK: - Private

    func setupViews() {
        view.backgroundColor = .classroomChildBG
        view.addSubview(tableView)
        view.addSubview(bottomView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        let bottomViewHeight: CGFloat = 40
        tableView.contentInset = .init(top: 0, left: 0, bottom: bottomViewHeight, right: 0)
        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(bottomViewHeight)
        }
    }
    
    func config(cell: RaiseHandTableViewCell, item: RoomUser) {
        cell.avatarImageView.kf.setImage(with: item.avatarURL)
        cell.nameLabel.text = item.name
        cell.clickAcceptHandler = { [weak self] in
            self?.acceptRaiseHandPublisher.accept(item)
        }
    }
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .classroomChildBG
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(RaiseHandTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.rowHeight = 40
        view.emptyDataSetSource = self
        return view
    }()
    
    lazy var bottomView: UIView = {
        let view = UIView()
        let viewAllButton = UIButton(type: .custom)
        viewAllButton.setTitle(localizeStrings("View All"), for: .normal)
        viewAllButton.setTitleColor(.color(type: .primary), for: .normal)
        viewAllButton.addTarget(self, action: #selector(onClickViewAll), for: .touchUpInside)
        view.addSubview(viewAllButton)
        viewAllButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()
}

extension RaiseHandListViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet _: UIScrollView) -> NSAttributedString? {
        .init(string: localizeStrings("NoRaiseHandUsers"),
              attributes: [
                  .foregroundColor: UIColor.color(type: .text),
                  .font: UIFont.systemFont(ofSize: 14),
              ])
    }

    func emptyDataSetShouldAllowScroll(_: UIScrollView) -> Bool {
        true
    }
}
