//
//  HomeCloudStorageViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/3/16.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import QuickLook
import AVKit
import Kingfisher

class CloudStorageViewController: CloudStorageDisplayViewController {
    var previewingUUID: String? {
        didSet {
            guard previewingUUID != oldValue else { return }
            if previewingUUID == nil {
                tableView.reloadData()
            }
        }
    }
    
    weak var previewingController: CustomPreviewViewController?
    var currentPreview: AnyPreview?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Reload selected
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAdditionalViews()
    }
    
    func setupAdditionalViews() {
        view.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        tableView.contentInset = .init(top: 0, left: 0, bottom: 88, right: 0)
        fillTopSafeAreaWith(color: .color(type: .background))
    }
    
    // MARK: - Action
    override func onClickEdit(_ sender: UIButton) {
        super.onClickEdit(sender)
        normalOperationStackView.isHidden = tableView.isEditing
        selectionStackView.isHidden = !tableView.isEditing
        addButton.isHidden = tableView.isEditing
        // To fire can delete action
        if !tableView.isEditing, !container.items.isEmpty {
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: .init(row: 0, section: 0))
        }
    }
    
    @objc func onClickCreateDirectory(_ sender: UIButton) {
        let alert = UIAlertController(title: localizeStrings("CreateDirectory"), message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = localizeStrings("CreateDirectoryPlaceholder")
        }
        alert.addAction(.init(title: localizeStrings("Cancel"), style: .cancel))
        let confirmAction = UIAlertAction(title: localizeStrings("Confirm"), style: .default) { [unowned alert, unowned self] _ in
            let foldName = alert.textFields![0].text ?? ""
            self.createDirctory(name: foldName)
        }
        alert.addAction(confirmAction)
        alert.textFields![0].rx.text.orEmpty
            .map { $0.count > 0 }
            .asDriver(onErrorJustReturn: false)
            .drive(confirmAction.rx.isEnabled)
            .disposed(by: alert.rx.disposeBag)
        mainContainer?.concreteViewController.present(alert, animated: true)
    }
    
    @objc func onClickFolderBack() {
        navigationController?.popViewController(animated: true)
        (mainContainer?.concreteViewController as? MainSplitViewController)?.cleanSecondary()
    }
    
    
    // MARK: - Lazy
    lazy var addButton: UIButton = {
        let addButton = SpringButton(type: .custom)
        addButton.setImage(UIImage(named: "storage_add"), for: .normal)
        var actions = UploadType.allCases.map { type -> Action in
            return Action(title: type.title, image: UIImage(named: type.imageName), style: .default) { _ in
                UploadUtility.shared.start(uploadType: type,
                                           fromViewController: self,
                                           delegate: self,
                                           presentStyle: .main)
            }
        }
        actions.append(.cancel)
        addButton.setupCommonCustomAlert(actions)
        return addButton
    }()

    lazy var backItem: UIButton = {
        let backItem = UIButton(type: .custom)
        backItem.setImage(UIImage(named: "arrowLeft")?.tintColor(.color(type: .text)), for: .normal)
        backItem.addTarget(self, action: #selector(onClickFolderBack), for: .touchUpInside)
        return backItem
    }()
    
    lazy var tableHeader: UIView = {
        let header = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 56)))
        header.backgroundColor = .color(type: .background)
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .color(type: .text, .strong)
        
        let leftStack = UIStackView(arrangedSubviews: [backItem, titleLabel])
        header.addSubview(leftStack)

        if currentDirectoryPath == "/" {
            titleLabel.text = localizeStrings("Cloud Storage")
            backItem.isHidden = true
            leftStack.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.height.equalTo(44)
            }
        } else {
            titleLabel.text = String(currentDirectoryPath.split(separator: "/").last ?? "")
            backItem.isHidden = false
            leftStack.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(44)
            }
            backItem.snp.makeConstraints { make in
                make.width.height.equalTo(44)
            }
        }

        header.addSubview(normalOperationStackView)
        normalOperationStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(header)
        }
        normalOperationStackView.arrangedSubviews.first?.snp.makeConstraints({ make in
            make.width.height.equalTo(44)
        })

        header.addSubview(selectionStackView)
        selectionStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalTo(header)
        }
        selectionStackView.isHidden = true
        return header
    }()
    
    lazy var normalOperationStackView: UIStackView = {
        let uploadListButton = UIButton(type: .custom)
        uploadListButton.setImage(UIImage(named: "upload_list")?.tintColor(.color(type: .text)), for: .normal)
        uploadListButton.addTarget(self, action: #selector(presentTask), for: .touchUpInside)
        
        let selectionButton = UIButton(type: .custom)
        selectionButton.setImage(UIImage(named: "cloud_storage_selection")?.tintColor(.color(type: .text)), for: .normal)
        selectionButton.addTarget(self, action: #selector(onClickEdit(_:)), for: .touchUpInside)
        
        let createDirectoryButton = UIButton(type: .custom)
        createDirectoryButton.setImage(UIImage(named: "create_directory")?.tintColor(.color(type: .text)), for: .normal)
        createDirectoryButton.addTarget(self, action: #selector(onClickCreateDirectory(_:)), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [uploadListButton, selectionButton, createDirectoryButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()
    
    lazy var finishSelectionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.color(type: .primary), for: .normal)
        button.setTitle(localizeStrings("Finish"), for: .normal)
        button.addTarget(self, action: #selector(onClickEdit(_:)), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)
        return button
    }()
    
    lazy var tasksViewController: UploadTasksViewController = {
        let vc = UploadTasksViewController()
        vc.modalPresentationStyle = .pageSheet
        return vc
    }()
    
    lazy var selectionStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [deleteAllButton, finishSelectionButton])
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()
    
    // MARK: - TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell =
                super.tableView(tableView, cellForRowAt: indexPath) as? CloudStorageTableViewCell
        else { fatalError() }
        cell.moreActionButton.isHidden = tableView.isEditing
        if !tableView.isEditing {
            let item = container.items[indexPath.row]
            let actions = actions(for: item)
            cell.moreActionButton.setupCommonCustomAlert(actions)
        }
        return cell
    }
    
    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !tableView.isEditing else { return nil }
        let item = container.items[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [unowned self] _ in
            let uiActions = self.actions(for: item).compactMap { action -> UIAction? in
                if action.isCancelAction() {
                    return nil
                }
                return UIAction(title: action.title, attributes: action.style == .destructive ? .destructive : []) { _ in
                    action.handler?(action)
                }
            }
            return UIMenu(title: "", children: uiActions)
        }
    }
    
    func actions(for item: StorageFileModel) -> [Action] {
        if item.resourceType == .directory {
            return [
                .init(title: localizeStrings("Rename"), style: .default, handler: { _ in
                    self.rename(item)
                }),
                .init(title: localizeStrings("Delete"), style: .destructive, handler: { _ in
                    self.deleteItems([item])
                }),
                .cancel
            ]
        }
        
        return [
            .init(title: localizeStrings("Preview"), style: .default, handler: { _ in
                self.preview(item)
            }),
            .init(title: localizeStrings("Rename"), style: .default, handler: { _ in
                self.rename(item)
            }),
            .init(title: localizeStrings("Share"), style: .default, handler: { _ in
                self.share(item)
            }),
            .init(title: localizeStrings("Delete"), style: .destructive, handler: { _ in
                self.deleteItems([item])
            }),
            .cancel
        ]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else { return }
        if isCompact() {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let item = container.items[indexPath.row]
        if item.resourceType == .directory {
            let directory = currentDirectoryPath + item.fileName + "/"
            let controller = CloudStorageViewController(currentDirectoryPath: directory)
            navigationController?.pushViewController(controller, animated: true)
            (mainContainer?.concreteViewController as? MainSplitViewController)?.cleanSecondary()
            return
        }
        guard item.usable else { return }
        preview(item)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        tableHeader.bounds.height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableHeader
    }
    
    // MARK: - Actions
    func share(_ item: StorageFileModel) {
        guard let index = container.items.firstIndex(of: item) else { return }
        let cell = tableView.cellForRow(at: .init(row: index, section: 0))
        let vc = UIActivityViewController(activityItems: [item.fileURL], applicationActivities: nil)
        mainContainer?.concreteViewController.popoverViewController(viewController: vc, fromSource: cell)
    }
    
    // MARK: - Preview
    func preview(_ item: StorageFileModel) {
        if let _ = previewingController {
            mainContainer?.removeTop()
        }
        previewingUUID = item.fileUUID
        let fileExtension = String(item.fileName.split(separator: ".").last ?? "")
        switch item.fileType {
        case .video:
            let vc = CustomAVPlayerViewController()
            let player = AVPlayer(url: item.urlOrEmpty)
            vc.dismissHandler = { [weak self] in
                self?.previewingUUID = nil
            }
            vc.player = player
            player.play()
            mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
        case .img:
            previewLocalFileUrlPath(source: .image(url: item.urlOrEmpty, fileExtension: fileExtension, fileName: item.fileName))
        default:
            // Preview with web link
            do {
                let jsonData = try JSONEncoder().encode(item)
                let itemJSONStr = (String(data: jsonData, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))  ?? ""
                let link = Env().webBaseURL + "/preview/\(itemJSONStr)"
                if let url = URL(string: link) {
                    let vc = WKWebViewController(url: url)
                    vc.modalPresentationStyle = .fullScreen
                    vc.title = item.fileName
                    vc.dismissHandler = { [weak self] in
                        guard let self = self else { return }
                        self.mainContainer?.removeTop()
                        self.previewingUUID = nil
                    }
                    mainContainer?.pushOnSplitPresentOnCompact(vc)
                    return
                }
            }
            catch {
                toast("encode storage item fail, \(error)")
            }
        }
    }
    
    func previewLocalFileUrlPath(source: CustomPreviewViewController.Source) {
        systemPreviewController.update(source: source)
        mainContainer?.pushOnSplitPresentOnCompact(systemPreviewController)
    }
    
    // MARK: - Lazy
    lazy var systemPreviewController: CustomPreviewViewController = {
        let vc = CustomPreviewViewController()
        vc.clickBackHandler = { [weak self] in
            self?.previewingUUID = nil
        }
        return vc
    }()
}

// MARK: - UploadUtilityDelegate
extension CloudStorageViewController: UploadUtilityDelegate {
    @objc func presentTask() {
        mainContainer?.concreteViewController.present(tasksViewController, animated: true, completion: nil)
    }
    
    func uploadFile(url: URL, region: FlatRegion, shouldAccessingSecurityScopedResource: Bool) {
        do {
            let dir = currentDirectoryPath
            var result = try UploadService.shared
                .createUploadTaskFrom(fileURL: url,
                                      region: region,
                                      shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource,
                                      targetDirectoryPath: currentDirectoryPath)
            let newTask = result.task.do(onSuccess: { fillUUID in
                if ConvertService.isFileConvertible(withFileURL: url) {
                    ConvertService.startConvert(fileUUID: fillUUID) { [weak self] result in
                        switch result {
                        case .success:
                            NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil, userInfo: ["dir": dir])
                        case .failure(let error):
                            self?.toast(error.localizedDescription)
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil, userInfo: ["dir": dir])
                }
            })
            result = (newTask, result.tracker)
            tasksViewController.appendTask(task: result.task, fileURL: url, targetDirectoryPath: currentDirectoryPath, subject: result.tracker)
            presentTask()
        }
        catch {
            toast("error create task \(error.localizedDescription)", timeInterval: 3)
        }
    }
    
    func uploadUtilityDidCompletePick(type: UploadType, url: URL) {
        switch type {
        case .image:
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        case .video:
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: false)
        case .audio:
            // It from file
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: true)
        case .doc:
            // It from file
            uploadFile(url: url, region: .CN_HZ, shouldAccessingSecurityScopedResource: true)
        }
    }
    
    func uploadUtilityDidStartVideoConverting() {
        showActivityIndicator()
    }
    
    func uploadUtilityDidFinishVideoConverting(error: Error?) {
        stopActivityIndicator()
        if let error = error {
            toast(error.localizedDescription)
        }
    }
    
    func uploadUtilityDidMeet(error: Error) {
        toast(error.localizedDescription)
    }
}
