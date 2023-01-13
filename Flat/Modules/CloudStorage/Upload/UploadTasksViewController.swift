//
//  UploadTasksViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxRelay
import RxSwift
import UIKit
import DZNEmptyDataSet

class UploadTasksViewController: UIViewController {
    // MARK: - Public

    func appendTask(task: Single<String>, fileURL: URL, targetDirectoryPath: String, subject: BehaviorRelay<UploadStatus>) {
        let disposable = task
            .observe(on: ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe()
        let uploadTask = UploadTask(url: fileURL, targetDirectoryPath: targetDirectoryPath, disposable: disposable)

        tasks.append((uploadTask, subject))
        tableView.reloadData()
    }

    struct UploadTask {
        let url: URL
        let targetDirectoryPath: String
        let disposable: Disposable
    }

    let cellIdentifier = "cellIdentifier"
    fileprivate var tasks: [(UploadTask, BehaviorRelay<UploadStatus>)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Action

    @objc func onClickClose() {
        dismiss(animated: true, completion: nil)
    }

    @objc func onClickCellOperationAt(indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        if let operation = task.1.value.availableOperation {
            switch operation {
            case .cancel:
                tasks[indexPath.row].0.disposable.dispose()
                UploadService.shared.removeTask(fromURL: task.0.url)
                tasks.remove(at: indexPath.row)
            case .reUpload:
                let shouldAccessingSecurityScopedResource = tasks[indexPath.row].0.url.isOutsideFile
                tasks[indexPath.row].0.disposable.dispose()
                UploadService.shared.removeTask(fromURL: task.0.url)
                tasks.remove(at: indexPath.row)
                do {
                    let result = try UploadService.shared
                        .createUploadTaskFrom(fileURL: task.0.url,
                                              region: .CN_HZ,
                                              shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource,
                                              targetDirectoryPath: task.0.targetDirectoryPath)
                    appendTask(task: result.task, fileURL: task.0.url, targetDirectoryPath: task.0.targetDirectoryPath, subject: result.tracker)
                } catch {
                    toast(error.localizedDescription)
                }
            }
            tableView.reloadData()
        }
    }

    // MARK: - Private

    func setupViews() {
        view.backgroundColor = .color(type: .background)
        view.addSubview(tableView)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.right.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(66)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    func config(cell: UploadTaskTableViewCell, task: (UploadTask, BehaviorRelay<UploadStatus>), indexPath: IndexPath) {
        let fileName = task.0.url.lastPathComponent
        let fileType = StorageFileModel.FileType(fileName: fileName)
        cell.iconImageView.image = UIImage(named: fileType.iconImageName)
        cell.fileNameLabel.text = fileName
        cell.operationClickHandler = { [weak self] in
            self?.onClickCellOperationAt(indexPath: indexPath)
        }
        var i = cell
        i.rx.disposeBag = DisposeBag()

        task.1
            .observe(on: MainScheduler.instance)
            .subscribe(with: cell, onNext: { weakCell, status in
                func observeProgress(withStatus status: UploadStatus) {
                    guard let progress = UploadService.shared.getRequestProgress(fromFileURL: task.0.url) else {
                        switch status {
                        case .finish:
                            weakCell.progressView.progress = 1
                        default:
                            weakCell.progressView.progress = 0
                        }
                        return
                    }
                    let progressDriver = progress.subscribe(on: MainScheduler.instance)
                        .asDriver(onErrorJustReturn: 0)
                        .map { Float($0) }

                    progressDriver
                        .drive(weakCell.progressView.rx.progress)
                        .disposed(by: weakCell.progressObserveDisposeBag!)

                    progressDriver
                        .map { String(format: "%.0f %%", $0 * 100) }
                        .drive(weakCell.statusLabel.rx.text)
                        .disposed(by: weakCell.progressObserveDisposeBag!)
                }

                logger.trace("upload status update \(status)")

                weakCell.progressView.progressTintColor = status.progressBarColor
                weakCell.statusLabel.text = status.statusDescription
                weakCell.statusLabel.textColor = status.statusColor
                weakCell.operationButton.setImage(UIImage(named: status.statusOperationImageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
                weakCell.progressObserveDisposeBag = DisposeBag()
                switch status {
                case let .error(error):
                    weakCell.progressView.progress = 0
                    weakCell.statusLabel.text = localizeStrings("Upload Fail") + " " + error.localizedDescription
                case .cancel:
                    weakCell.progressView.progress = 0
                case .idle:
                    weakCell.progressView.progress = 0
                case .preparing:
                    weakCell.progressView.progress = 0
                case .prepareFinish:
                    weakCell.progressView.progress = 0
                case .uploading:
                    observeProgress(withStatus: status)
                case .uploadFinish:
                    weakCell.progressView.progress = 1
                case .reporting:
                    weakCell.progressView.progress = 1
                case .reportFinish:
                    weakCell.progressView.progress = 1
                case .finish:
                    weakCell.progressView.progress = 1
                }
            })
            .disposed(by: cell.rx.disposeBag)
    }

    // MARK: - Lazy

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .color(type: .background)
        view.contentInsetAdjustmentBehavior = .never
        view.separatorStyle = .none
        view.register(.init(nibName: String(describing: UploadTaskTableViewCell.self), bundle: nil),
                      forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.rowHeight = 70
        view.showsVerticalScrollIndicator = false
        view.emptyDataSetSource = self
        return view
    }()

    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .color(type: .background)
        let topLabel = UILabel(frame: .zero)
        topLabel.text = localizeStrings("Uploading List")
        topLabel.textColor = .color(type: .text)
        topLabel.font = .systemFont(ofSize: 16, weight: .medium)

        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "upload_cancel"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)

        view.addSubview(topLabel)
        topLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalTo(66)
        }
        return view
    }()
}

extension UploadTasksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! UploadTaskTableViewCell
        let task = tasks[indexPath.row]
        config(cell: cell, task: task, indexPath: indexPath)
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UploadTasksViewController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet _: UIScrollView) -> NSAttributedString? {
        .init(string: localizeStrings("NoUploadingWarnings"),
              attributes: [
                  .foregroundColor: UIColor.color(type: .text),
                  .font: UIFont.systemFont(ofSize: 14),
              ])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        UIImage(named: "cloud_empty", in: nil, compatibleWith: traitCollection)
    }
}
