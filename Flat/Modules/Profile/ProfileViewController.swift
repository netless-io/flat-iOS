//
//  ProfileUIViewController.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/6.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit
import RxSwift
import CropViewController

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let cellIdentifier = "profileCellIdentifier"
    
    var bindInfo: [BindingType: Bool]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupObserver()
        updateBindingInfo()
    }
    
    func setupObserver() {
        NotificationCenter.default.rx
            .notification(avatarUpdateNotificationName)
            .subscribe(with: self, onNext: { ws, _ in
                ws.tableView.reloadData()
            })
            .disposed(by: rx.disposeBag)
    }
    
    func setupViews() {
        title = NSLocalizedString("Profile", comment: "")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.reloadData()
    }
    
    func updateBindingInfo(showIndicator: Bool = false) {
        if (showIndicator) {
            showActivityIndicator()
        }
        ApiProvider.shared.request(fromApi: BindListRequest()) { result in
            self.stopActivityIndicator()
            switch result {
            case .success(let list):
                var info = self.bindInfo ?? [:]
                for type in BindingType.allCases {
                    switch type {
                    case .WeChat:
                        info[type] = list.wechat
                    case .Apple:
                        info[type] = list.apple
                    case .Github:
                        info[type] = list.github
                    }
                }
                self.bindInfo = info
            case .failure(let error):
                self.toast(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Actions
    func onClickAvatar() {
        let vc = UIImagePickerController()
        vc.delegate = self
        mainContainer?.concreteViewController.present(vc, animated: true)
    }
    
    func onClickNickName() {
        let alert = UIAlertController(title: NSLocalizedString("Update nickname", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = AuthStore.shared.user?.name
        }
        alert.addAction(.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(.init(title: NSLocalizedString("Confirm", comment: ""), style: .default, handler: { _ in
            guard let text = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                self.toast(NSLocalizedString("Please enter your nickname", comment: ""))
                return
            }
            self.showActivityIndicator()
            ApiProvider.shared.request(fromApi: UserRenameRequest(name: text)) { result in
                self.stopActivityIndicator()
                switch result {
                case .success:
                    AuthStore.shared.updateName(text)
                    self.toast(NSLocalizedString("Update nickname success", comment: ""))
                    self.tableView.reloadData()
                case .failure(let error):
                    self.toast(error.localizedDescription)
                }
            }
        }))
        present(alert, animated: true)
    }
    
    func onClickBindType(_ type: BindingType) {
        guard let binded = bindInfo?[type] else { return }
        if !binded {
            switch type {
            case .WeChat:
                showActivityIndicator()
                let binding = WechatBinding { [weak self] error in
                    self?.stopActivityIndicator()
                    if let error = error {
                        self?.toast(error.localizedDescription)
                    } else {
                        self?.updateBindingInfo(showIndicator: true)
                    }
                }
                binding.startBinding(onCoordinator: globalLaunchCoordinator!)
            case .Apple:
                return
            case .Github:
                return
            }
        } else {
            showCheckAlert(message: NSLocalizedString("Unbound Tips", comment: "")) {
                self.showActivityIndicator()
                ApiProvider.shared.request(fromApi: RemoveBindingRequest(type: type)) { result in
                    self.stopActivityIndicator()
                    switch result {
                    case .success(let value):
                        AuthStore.shared.updateToken(value.token)
                        self.updateBindingInfo()
                    case .failure(let error):
                        self.toast(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: - Private
    fileprivate func setupCell(_ cell: UITableViewCell, type: BindingType) {
        cell.textLabel?.textColor = .text
        cell.backgroundColor = .whiteBG
        cell.contentView.backgroundColor = .whiteBG
        cell.textLabel?.text = NSLocalizedString("Binding \(type.identifierString)", comment: "")
        cell.accessoryView = nil
        cell.selectionStyle = .none
        if let bindInfo = bindInfo {
            let binded = bindInfo[type] ?? false
            cell.detailTextLabel?.text = NSLocalizedString(binded ? "Binded" : "Unbound", comment: "")
            cell.detailTextLabel?.textColor = binded ? .systemGreen : .systemRed
        } else {
            cell.detailTextLabel?.text = NSLocalizedString("Loading", comment: "")
            cell.detailTextLabel?.textColor = .systemGray
        }
    }
    
    // MARK: - Lazy
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .whiteBG
        view.separatorStyle = .none
        view.rowHeight = 47
        view.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 22
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView(frame: .zero)
            let label = UILabel()
            label.text = NSLocalizedString("Account binding information", comment: "")
            view.addSubview(label)
            label.font = .systemFont(ofSize: 12, weight: .light)
            label.textColor = .subText
            label.snp.makeConstraints {
                $0.left.equalToSuperview().inset(16)
                $0.centerY.equalToSuperview()
            }
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        if indexPath.section == 0 {
            cell.textLabel?.textColor = .text
            cell.detailTextLabel?.textColor = .subText
            cell.backgroundColor = .whiteBG
            cell.contentView.backgroundColor = .whiteBG
            cell.selectionStyle = .none
            cell.accessoryView = nil
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Nickname", comment: "")
                cell.detailTextLabel?.text = AuthStore.shared.user?.name ?? ""
            } else {
                cell.textLabel?.text = NSLocalizedString("Avatar", comment: "")
                cell.detailTextLabel?.text = ""
                let avatarView = UIImageView(frame: .init(origin: .zero, size: .init(width: 44, height: 44)))
                avatarView.backgroundColor = .systemGray
                avatarView.kf.setImage(with: AuthStore.shared.user?.avatar)
                avatarView.clipsToBounds = true
                avatarView.layer.cornerRadius = 22
                cell.accessoryView = avatarView
            }
        } else {
            setupCell(cell, type: .init(rawValue: indexPath.row)!)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                onClickNickName()
            } else {
                onClickAvatar()
            }
        }
        if indexPath.section == 1 {
            onClickBindType(.init(rawValue: indexPath.row)!)
        }
    }
}

extension ProfileViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        let data = image.jpegData(compressionQuality: 1)
        let path = NSTemporaryDirectory() + UUID().uuidString + ".jpg"
        FileManager.default.createFile(atPath: path, contents: data)
        let fileURL = URL(fileURLWithPath: path)
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let name = fileURL.lastPathComponent
            let size = (attribute[.size] as? NSNumber)?.intValue ?? 0
            var uuid: String!
            showActivityIndicator(text: NSLocalizedString("Uploading", comment: ""))
            ApiProvider.shared.request(fromApi: PrepareAvatarUploadRequest(fileName: name, fileSize: size, region: .CN_HZ))
                .flatMap { [weak self] info throws -> Observable<Void> in
                    guard let self = self else { return .error("self not exist") }
                    uuid = info.fileUUID
                    return try self.upload(info: info, fileURL: fileURL)
                }
                .flatMap { _ -> Observable<URL> in
                    let finishRequest = UploadAvatarFinishRequest(fileUUID: uuid, region: .CN_HZ)
                    return ApiProvider.shared.request(fromApi: finishRequest).map { $0.avatarURL }
                }
                .subscribe(with: self, onNext: { weakSelf, avatarUrl in
                    weakSelf.stopActivityIndicator()
                    AuthStore.shared.updateAvatar(avatarUrl)
                    weakSelf.toast(NSLocalizedString("Upload Success", comment: ""))
                }, onError: { weakSelf, error in
                    weakSelf.toast(error.localizedDescription)
                })
                .disposed(by: rx.disposeBag)
        }
        catch {
            toast(error.localizedDescription)
        }
        dismiss(animated: true)
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        let vc = CropViewController(croppingStyle: .circular, image: image)
        vc.delegate = self
        dismiss(animated: false) {
            self.mainContainer?.concreteViewController.present(vc, animated: true)
        }
    }
    
    private func upload(info: UploadInfo, fileURL: URL) throws -> Observable<Void> {
        let session = URLSession(configuration: .default)
        let boundary = UUID().uuidString
        var request = URLRequest(url: info.policyURL, timeoutInterval: 60 * 10)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let encodedFileName = String(URLComponents(url: fileURL, resolvingAgainstBaseURL: false)?
            .percentEncodedPath
            .split(separator: "/")
            .last ?? "")
        
        let partFormData = MultipartFormData(fileManager: FileManager.default, boundary: boundary)
        let headers: [(String, String)] = [
            ("key", info.filePath),
            ("name", fileURL.lastPathComponent),
            ("policy", info.policy),
            ("OSSAccessKeyId", Env().ossAccessKeyId),
            ("success_action_status", "200"),
            ("callback", ""),
            ("signature", info.signature),
            ("Content-Disposition", "attachment; filename=\"\(encodedFileName)\"; filename*=UTF-8''\(encodedFileName)")
        ]
        for (key, value) in headers {
            let d = value.data(using: .utf8)!
            partFormData.append(d, withName: key)
        }
        partFormData.append(fileURL, withName: "file")
        let data = try partFormData.encode()
        return .create { s in
            let task = session.uploadTask(with: request, from: data) { data, response, error in
                guard error == nil else {
                    s.onError(error!)
                    s.onCompleted()
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    s.onError("not a http response")
                    s.onCompleted()
                    return
                }
                guard httpResponse.statusCode == 200 else {
                    s.onError("not correct statusCode, \(httpResponse.statusCode)")
                    s.onCompleted()
                    return
                }
                s.onNext(())
                s.onCompleted()
            }
            task.resume()
            return Disposables.create {
                if let _ = task.error {
                    return
                }
                if !task.progress.isFinished {
                    task.cancel()
                }
            }
        }
    }
}
