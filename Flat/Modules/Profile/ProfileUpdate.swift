//
//  ProfileUpdate.swift
//  Flat
//
//  Created by xuyunshi on 2023/8/18.
//  Copyright © 2023 agora.io. All rights reserved.
//

import UIKit
import CropViewController
import Photos
import RxSwift

class ProfileUpdate: NSObject {
    private weak var root: UIViewController?
    
    func startUpdateAvatar(from fromController: UIViewController) {
        root = fromController
        func failPhotoPermission() {
            fromController.showCheckAlert(checkTitle: localizeStrings("GoSetting"), message: localizeStrings("PhotoDenyTip")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] s in
                DispatchQueue.main.async {
                    if s == .denied {
                        failPhotoPermission()
                        return
                    }
                    self?.startUpdateAvatar(from: fromController)
                }
            }
        case .denied:
            failPhotoPermission()
        default:
            let vc = UIImagePickerController()
            vc.delegate = self
            root?.present(vc, animated: true)
        }
    }
}

extension ProfileUpdate: CropViewControllerDelegate {
    func cropViewController(_: CropViewController, didCropToCircularImage image: UIImage, withRect _: CGRect, angle _: Int) {
        guard let root else { return }
        var targetImage = image
        let maxSize = CGSize(width: 244, height: 244)
        if image.size.width > maxSize.width || image.size.height > maxSize.height {
            UIGraphicsBeginImageContextWithOptions(maxSize, false, 3)
            image.draw(in: .init(origin: .zero, size: maxSize))
            if let t = UIGraphicsGetImageFromCurrentImageContext() {
                targetImage = t
            }
            UIGraphicsEndImageContext()
        }

        let data = targetImage.pngData()
        let path = NSTemporaryDirectory() + UUID().uuidString + ".png"
        FileManager.default.createFile(atPath: path, contents: data)
        let fileURL = URL(fileURLWithPath: path)
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let name = fileURL.lastPathComponent
            let size = (attribute[.size] as? NSNumber)?.intValue ?? 0
            root.showActivityIndicator(text: localizeStrings("Uploading"))
            ApiProvider.shared.request(fromApi: PrepareAvatarUploadRequest(fileName: name, fileSize: size))
                .flatMap { [weak self] info throws -> Observable<UploadInfo> in
                    guard let self else { return .error("self not exist") }
                    return try self.upload(info: info, fileURL: fileURL).map { info }
                }
                .flatMap { info -> Observable<URL> in
                    let finishRequest = UploadAvatarFinishRequest(fileUUID: info.fileUUID)
                    let avatarURL = info.ossDomain.appendingPathComponent(info.ossFilePath)
                    return ApiProvider.shared.request(fromApi: finishRequest).map { _ in avatarURL }
                }
                .observe(on: MainScheduler.instance)
                .subscribe(with: root, onNext: { root, avatarUrl in
                    root.stopActivityIndicator()
                    AuthStore.shared.updateAvatar(avatarUrl)
                    root.toast(localizeStrings("Upload Success"))
                }, onError: { root, error in
                    root.toast(error.localizedDescription)
                })
                .disposed(by: rx.disposeBag)
        } catch {
            root.toast(error.localizedDescription)
        }
        root.dismiss(animated: true)
    }
}

extension ProfileUpdate: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard
            let root,
            let image = info[.originalImage] as? UIImage else { return }
        let vc = CropViewController(croppingStyle: .circular, image: image)
        vc.delegate = self
        root.dismiss(animated: false) {
            root.present(vc, animated: true)
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
            ("Content-Disposition", "attachment; filename=\"\(encodedFileName)\"; filename*=UTF-8''\(encodedFileName)"),
        ]
        for (key, value) in headers {
            let d = value.data(using: .utf8)!
            partFormData.append(d, withName: key)
        }
        partFormData.append(fileURL, withName: "file")
        let data = try partFormData.encode()
        return .create { s in
            let task = session.uploadTask(with: request, from: data) { _, response, error in
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
