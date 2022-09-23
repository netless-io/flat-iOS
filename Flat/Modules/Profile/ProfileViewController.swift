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
        title = localizeStrings("Profile")
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
    
    // MARK: - Lazy
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = .color(type: .background)
        view.separatorStyle = .none
        view.register(ProfileTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        view.delegate = self
        view.dataSource = self
        view.tableHeaderView = .minHeaderView()
        return view
    }()
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == 0 ? 68 : 48
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ProfileTableViewCell
        switch indexPath.row {
        case 0:
            cell.avatarImageView.isHidden = false
            cell.profileDetailTextLabel.isHidden = true
            cell.profileTitleLabel.text = localizeStrings("Avatar")
            cell.avatarImageView.kf.setImage(with: AuthStore.shared.user?.avatar)
        case 1:
            cell.avatarImageView.isHidden = true
            cell.profileDetailTextLabel.isHidden = false
            cell.profileTitleLabel.text = localizeStrings("Nickname")
            cell.profileDetailTextLabel.text = AuthStore.shared.user?.name
        default:
            cell.avatarImageView.isHidden = true
            cell.profileDetailTextLabel.isHidden = false
            let type = BindingType(rawValue: indexPath.row - 2)!
            cell.profileTitleLabel.text = localizeStrings(type.identifierString)
            if let bindInfo = bindInfo {
                let binded = bindInfo[type] ?? false
                cell.profileDetailTextLabel.text = localizeStrings(binded ? "Binded" : "Unbound")
                cell.profileDetailTextLabel.textColor = binded ? .color(type: .success) : .color(type: .text)
            } else {
                cell.profileDetailTextLabel.text = localizeStrings("Loading")
                cell.profileDetailTextLabel.textColor = .color(type: .text)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            onClickAvatar()
        case 1:
            onClickNickName()
        default:
            onClickBindType(.init(rawValue: indexPath.row - 2)!)
        }
    }
}

extension ProfileViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        var targetImage = image
        let maxSize = CGSize(width: 244, height: 244)
        if image.size.width > maxSize.width || image.size.height > maxSize.height {
            UIGraphicsBeginImageContextWithOptions(maxSize, true, 3)
            image.draw(in: .init(origin: .zero, size: maxSize))
            if let t = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = t
            }
            UIGraphicsEndImageContext()
        }
        
        let data = targetImage.jpegData(compressionQuality: 1)
        let path = NSTemporaryDirectory() + UUID().uuidString + ".jpg"
        FileManager.default.createFile(atPath: path, contents: data)
        let fileURL = URL(fileURLWithPath: path)
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let name = fileURL.lastPathComponent
            let size = (attribute[.size] as? NSNumber)?.intValue ?? 0
            showActivityIndicator(text: NSLocalizedString("Uploading", comment: ""))
            ApiProvider.shared.request(fromApi: PrepareAvatarUploadRequest(fileName: name, fileSize: size))
                .flatMap { [weak self] info throws -> Observable<UploadInfo> in
                    guard let self = self else { return .error("self not exist") }
                    return try self.upload(info: info, fileURL: fileURL).map { info}
                }
                .flatMap { info -> Observable<URL> in
                    let finishRequest = UploadAvatarFinishRequest(fileUUID: info.fileUUID)
                    let avatarURL = info.ossDomain.appendingPathComponent(info.ossFilePath)
                    return ApiProvider.shared.request(fromApi: finishRequest).map { _ in avatarURL }
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
        var request = URLRequest(url: info.ossDomain, timeoutInterval: 60 * 10)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let encodedFileName = String(URLComponents(url: fileURL, resolvingAgainstBaseURL: false)?
            .percentEncodedPath
            .split(separator: "/")
            .last ?? "")
        
        let partFormData = MultipartFormData(fileManager: FileManager.default, boundary: boundary)
        let headers: [(String, String)] = [
            ("key", info.ossFilePath),
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
