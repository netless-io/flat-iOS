//
//  ClassroomViewController+ImagePicker.swift
//  Flat
//
//  Created by xuyunshi on 2023/5/24.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import RxSwift

extension ClassRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard
            let image = info[.originalImage] as? UIImage,
            let imageData = image.jpegData(compressionQuality: 0.1)
        else {
            globalLogger.error("Get image data fail")
            toast("Get image data fail")
            return
        }
        dismiss(animated: true)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        do {
            try imageData.write(to: fileURL)
            
            let attribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let name = fileURL.lastPathComponent
            let size = (attribute[.size] as? NSNumber)?.intValue ?? 0
            showActivityIndicator(text: localizeStrings("Uploading"))
            ApiProvider.shared.request(fromApi: TempPhotoStartRequest(fileName: name, fileSize: size))
                .flatMap { [weak self] info throws -> Observable<UploadInfo> in
                    guard let self else { return .error("self not exist") }
                    return try self.upload(info: info, fileURL: fileURL).map { info }
                }
                .flatMap { info -> Observable<URL> in
                    let finishRequest = TempPhotoFinishRequest(fileUUID: info.fileUUID)
                    let url = info.ossDomain.appendingPathComponent(info.ossFilePath)
                    return ApiProvider.shared.request(fromApi: finishRequest).map { _ in url }
                }
                .subscribe(with: self, onNext: { weakSelf, url in
                    weakSelf.stopActivityIndicator()
                    weakSelf.fastboardViewController.insert(image: image, url: url)
                }, onError: { weakSelf, error in
                    weakSelf.stopActivityIndicator()
                    weakSelf.toast(error.localizedDescription)
                })
                .disposed(by: rx.disposeBag)
        }
        catch {
            globalLogger.error("write tmp image to path error \(error)")
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
