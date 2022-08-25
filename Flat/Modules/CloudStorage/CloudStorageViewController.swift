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
    var previewingUUID: String? {
        didSet {
            if let newId = previewingUUID, let newIndex = container.items.firstIndex(where: { $0.fileUUID == newId}) {
                tableView.reloadRows(at: [IndexPath(row: newIndex, section: 0)], with: .none)
            }
            if let oldId = oldValue, let oldIndex = container.items.firstIndex(where: { $0.fileUUID == oldId}) {
                tableView.reloadRows(at: [IndexPath(row: oldIndex, section: 0)], with: .none)
            }
        }
    }
    
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
            make.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.size.equalTo(CGSize(width: 80, height: 64))
        }
        tableView.contentInset = .init(top: 0, left: 0, bottom: 88, right: 0)
        fillTopSafeAreaWith(color: .whiteBG)
    }
    
    lazy var addButton: UIButton = {
        let addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(named: "storage_add"), for: .normal)
        addButton.addTarget(self, action: #selector(onClickAdd), for: .touchUpInside)
        return addButton
    }()
    
    lazy var tableHeader: UIView = {
        let header = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 56)))
        header.backgroundColor = .whiteBG
        
        let titleLabel = UILabel()
        titleLabel.text = localizeStrings("Cloud Storage")
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .strongText
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
        let selectionButton = UIButton(type: .custom)
        selectionButton.setImage(UIImage(named: "cloud_storage_selection")?.tintColor(.text), for: .normal)
        selectionButton.addTarget(self, action: #selector(onClickEdit(_:)), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [selectionButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()
    
    lazy var finishSelectionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.brandColor, for: .normal)
        button.setTitle(localizeStrings("Finish"), for: .normal)
        button.addTarget(self, action: #selector(onClickEdit(_:)), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 16, left: 16, bottom: 16, right: 16)
        return button
    }()
    
    override func onClickEdit(_ sender: UIButton) {
        super.onClickEdit(sender)
        normalOperationStackView.isHidden = tableView.isEditing
        selectionStackView.isHidden = !tableView.isEditing
        addButton.isHidden = tableView.isEditing
    }
    
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
        
        let item = container.items[indexPath.row]
        let isPreviewing = item.fileUUID == previewingUUID
        cell.contentView.backgroundColor = isPreviewing ? .cellSelectedBG : .whiteBG
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let item = container.items[indexPath.row]
        guard item.usable else { return }

        let cell = tableView.cellForRow(at: indexPath)
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(.init(title: NSLocalizedString("Preview", comment: ""), style: .default, handler: { [unowned self] _ in
            if item.convertStep == .converting {
                self.toast(NSLocalizedString("FileIsConverting", comment: ""))
                return
            }
            self.preview(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { [unowned self] _ in
            self.rename(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { [unowned self] _ in
            self.share(item)
        }))
        alertVC.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        popoverViewController(viewController: alertVC, fromSource: cell)
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
    @objc func onClickAdd() {
        let vc = UploadHomeViewController()
        mainContainer?.push(vc)
    }
    
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
