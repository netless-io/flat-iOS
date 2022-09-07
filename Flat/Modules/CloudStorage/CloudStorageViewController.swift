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
import SafariServices
import Kingfisher

class CloudStorageViewController: CloudStorageDisplayViewController {
    var previewingUUID: String?
    
    weak var previewingController: CustomPreviewViewController?
    var currentPreview: AnyPreview?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        cleanPreviewResource()
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
    
    
    // MARK: - Lazy
    lazy var addButton: UIButton = {
        let addButton = UIButton(type: .custom)
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
    
    lazy var tableHeader: UIView = {
        let header = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 56)))
        header.backgroundColor = .color(type: .background)
        
        let titleLabel = UILabel()
        titleLabel.text = localizeStrings("Cloud Storage")
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .color(type: .text, .strong)
        header.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
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
        let stack = UIStackView(arrangedSubviews: [uploadListButton, selectionButton])
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
        cell.moreActionButton.isHidden = false
        cell.moreActionButton.tag = indexPath.row
        cell.moreActionButton.addTarget(self, action: #selector(onClickMoreAction(sender:)))
        cell.selectionStyle = .none
        return cell
    }
    
    @objc func onClickMoreAction(sender: UIButton) {
        let item = container.items[sender.tag]
        let hasCompact = mainContainer?.concreteViewController.traitCollection.hasCompact ?? false
        if hasCompact {
            presentCommonCustomAlert(actions(for: item))
        } else {
            popOverCommonCustomAlert(actions(for: item), fromSource: sender, permittedArrowDirections: [.right])
        }
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
        [
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
        if isCompact() {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard !tableView.isEditing else { return }
        let item = container.items[indexPath.row]
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
        cleanPreviewResource()
        previewingUUID = item.fileUUID
        let fileExtension = String(item.fileName.split(separator: ".").last ?? "")
        switch item.fileType {
        case .video:
            let vc = CustomAVPlayerViewController()
            let player = AVPlayer(url: item.fileURL)
            vc.dismissHandler = { [weak self] in
                self?.cleanPreviewResource()
            }
            vc.player = player
            player.play()
            mainContainer?.concreteViewController.present(vc, animated: true, completion: nil)
        case .img:
            showActivityIndicator()
            KingfisherManager.shared.retrieveImageDiskCachePath(fromURL: item.fileURL) { [weak self] result in
                DispatchQueue.main.async {
                    self?.stopActivityIndicator()
                    switch result {
                    case .success(let path):
                        self?.previewLocalFileUrlPath(path,
                                                      fileExtension: fileExtension,
                                                      fileName: item.fileName)
                    case .failure(let error):
                        self?.toast(error.localizedDescription)
                    }
                }
            }
        default:
            let isProjector = item.resourceType == .projector
            // Preview dynamic with web preview
            if ConvertService.convertingTaskTypeFor(url: item.fileURL) == .dynamic {
                let formatURL = item.fileURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                let link = Env().webBaseURL + "/preview/\(formatURL)/\(item.taskToken)/\(item.taskUUID)/\(item.region.rawValue)/\(isProjector ? "projector/" : "")"
                if let url = URL(string: link) {
                    let config = SFSafariViewController.Configuration()
                    config.barCollapsingEnabled = true
                    config.entersReaderIfAvailable = false
                    let vc = SFSafariViewController(url: url, configuration: config)
                    vc.delegate = self
                    vc.dismissButtonStyle = .close
                    vc.title = item.fileName
                    mainContainer?.pushOnSplitPresentOnCompact(vc)
                    return
                }
            }
            
            showActivityIndicator()
            let request = URLRequest(url: item.fileURL,
                                     cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 60)
            let task = URLSession.shared.downloadTask(with: request) { [weak self] targetUrl, response, error in
                DispatchQueue.main.async {
                    self?.stopActivityIndicator()
                }
                guard error == nil else {
                    self?.toast(error!.localizedDescription)
                    return
                }
                guard let url = targetUrl else {
                    self?.toast("download fail")
                    return
                }
                var tempURL = FileManager.default.temporaryDirectory
                tempURL.appendPathComponent(UUID().uuidString)
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                }
                catch {
                    DispatchQueue.main.async {
                        self?.toast(error.localizedDescription)
                    }
                }
                DispatchQueue.main.async {
                    self?.previewLocalFileUrlPath(tempURL.path,
                                                  fileExtension: fileExtension,
                                                  fileName: item.fileName)
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
            task.resume()
        }
    }
    
    func previewLocalFileUrlPath(_ path: String,
                                 fileExtension: String,
                                 fileName: String) {
        var tempURL = FileManager.default.temporaryDirectory
        tempURL.appendPathComponent(UUID().uuidString + ".\(fileExtension)")
        do {
            try FileManager.default.copyItem(atPath: path, toPath: tempURL.path)
            let previewItem = AnyPreview(previewItemURL: URL(fileURLWithPath: tempURL.path), title: fileName)
            currentPreview = previewItem
            let vc = CustomPreviewViewController()
            self.previewingController = vc
            vc.dataSource = self
            vc.delegate = self
            vc.clickBackHandler = { [weak self] in
                self?.cleanPreviewResource()
            }
            mainContainer?.pushOnSplitPresentOnCompact(vc)
        }
        catch {
            logger.error("previewLocalFileUrlPath, \(error)")
            toast(error.localizedDescription)
        }
    }
    
    func cleanPreviewResource() {
        previewingUUID = nil
        if let url = currentPreview?.previewItemURL {
            do {
                try FileManager.default.removeItem(at: url)
            }
            catch {
                logger.error("remove preview item fail")
            }
        }
        currentPreview = nil
    }
}

extension CloudStorageViewController: QLPreviewControllerDelegate {
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        cleanPreviewResource()
    }
}

extension CloudStorageViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        currentPreview == nil ? 0 : 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        currentPreview!
    }
}

extension CloudStorageViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        mainContainer?.removeTop()
        previewingUUID = nil
    }
}

// MARK: - UploadUtilityDelegate
extension CloudStorageViewController: UploadUtilityDelegate {
    @objc func presentTask() {
        mainContainer?.concreteViewController.present(tasksViewController, animated: true, completion: nil)
    }
    
    func uploadFile(url: URL, region: FlatRegion, shouldAccessingSecurityScopedResource: Bool) {
        do {
            var result = try UploadService.shared
                .createUploadTaskFrom(fileURL: url,
                                      region: region,
                                      shouldAccessingSecurityScopedResource: shouldAccessingSecurityScopedResource)
            let newTask = result.task.do(onSuccess: { fillUUID in
                if ConvertService.isFileConvertible(withFileURL: url) {
                    ConvertService.startConvert(fileUUID: fillUUID, isWhiteboardProjector: ConvertService.isDynamicPpt(url: url)) { [weak self] result in
                        switch result {
                        case .success:
                            NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                        case .failure(let error):
                            self?.toast(error.localizedDescription)
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: cloudStorageShouldUpdateNotificationName, object: nil)
                }
            })
            result = (newTask, result.tracker)
            tasksViewController.appendTask(task: result.task, fileURL: url, subject: result.tracker)
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
