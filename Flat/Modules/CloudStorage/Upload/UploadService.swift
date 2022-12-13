//
//  UploadService.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/7.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

enum UploadTaskOperation {
    case reUpload
    case cancel
}

enum UploadStatus {
    case error(Error)
    case cancel
    case idle
    case preparing
    case prepareFinish
    case uploading
    case uploadFinish
    case reporting
    case reportFinish
    case finish

    var availableOperation: UploadTaskOperation? {
        switch self {
        case .error:
            return .reUpload
        case .finish:
            return nil
        default:
            return .cancel
        }
    }

    var statusOperationImageName: String {
        switch self {
        case .finish:
            return "upload_success"
        case .error:
            return "upload_reupload"
        default:
            return "upload_cancel"
        }
    }

    var statusDescription: String? {
        let str: String
        switch self {
        case .preparing, .prepareFinish: str = "Upload Preparing"
        case .error: str = "Upload Fail"
        case .finish: str = "Upload Success"
        case .idle: str = "Upload Idle"
        case .reportFinish, .reporting: str = "Upload Reporting"
        default: return nil
        }
        return localizeStrings(str)
    }

    var statusColor: UIColor {
        switch self {
        case .finish:
            return .systemGreen
        case .cancel, .error:
            return .systemRed
        default:
            return .color(type: .text)
        }
    }

    var progressBarColor: UIColor {
        switch self {
        case .finish, .reportFinish, .uploadFinish:
            return .systemGreen
        case .cancel, .error:
            return .systemRed
        default:
            return .color(type: .primary)
        }
    }
}

extension URL {
    /// Is the file outside of sandbox
    var isOutsideFile: Bool {
        absoluteString.contains("/Shared/AppGroup")
    }
}

class UploadService {
    static let shared = UploadService()
    private init() {}

    var taskIdentifierMap: [URL: Int] = [:]
    var pendingRequests: [URLSessionUploadTask] = []
    var trackers: [URL: BehaviorRelay<UploadStatus>] = [:]

    func getRequestProgress(fromFileURL: URL) -> Observable<Double>? {
        guard let identifier = taskIdentifierMap[fromFileURL],
              let task = pendingRequests.first(where: { $0.taskIdentifier == identifier })
        else {
            return nil
        }
        return Observable<Int>.interval(.milliseconds(500), scheduler: ConcurrentDispatchQueueScheduler(queue: .global()))
            .map { _ in task.progress.fractionCompleted }
            .take(until: { $0 >= 1 || task.progress.isFinished || task.progress.isCancelled })
    }

    func removeTask(fromURL: URL) {
        guard let identifier = taskIdentifierMap[fromURL] else { return }
        taskIdentifierMap.removeValue(forKey: fromURL)
        pendingRequests.removeAll(where: { $0.taskIdentifier == identifier })
        trackers.removeValue(forKey: fromURL)
    }

    ///   - shouldAccessingSecurityScopedResource: If the file is outside of the app, it should be 'true'
    func createUploadTaskFrom(fileURL: URL, region: FlatRegion, shouldAccessingSecurityScopedResource: Bool, targetDirectoryPath: String) throws -> (task: Single<String>, tracker: BehaviorRelay<UploadStatus>) {
        if shouldAccessingSecurityScopedResource {
            let accessing = fileURL.startAccessingSecurityScopedResource()
            guard accessing else { throw "access file error, \(fileURL)" }
        }
        var fileUUID: String?
        let tracker = BehaviorRelay<UploadStatus>(value: .idle)
        trackers[fileURL] = tracker
        tracker.accept(.preparing)
        let task = prepare(fileURL: fileURL, region: region, targetDirectoryPath: targetDirectoryPath)
            .do(onNext: { info in
                tracker.accept(.prepareFinish)
                fileUUID = info.fileUUID
            })
            .flatMap { [unowned self] info -> Observable<Void> in
                try self.upload(fileURL: fileURL, info: info)
                    .do(onSubscribed: {
                        tracker.accept(.uploading)
                    })
            }
            .do(onNext: { _ in
                tracker.accept(.uploadFinish)
            }, onError: { error in
                if let fileUUID = fileUUID {
                    logger.error("cancel task by error \(error) \(fileUUID)")
                    ApiProvider.shared.request(fromApi: CancelUploadRequest(fileUUIDs: [fileUUID]), completionHandler: { _ in })
                }
            })
            .flatMap { [unowned self] _ -> Observable<String> in
                self.reportFinish(fileUUID: fileUUID!, region: region, isWhiteboardProjector: ConvertService.isDynamicPpt(url: fileURL))
                    .do(onSubscribed: {
                        tracker.accept(.reporting)
                    }).map { _ in fileUUID! }
            }
            .asSingle()
            .do(onSuccess: { _ in
                tracker.accept(.reportFinish)
                tracker.accept(.finish)
                if shouldAccessingSecurityScopedResource {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }, onError: { error in
                tracker.accept(.error(error))
                if shouldAccessingSecurityScopedResource {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }, onDispose: { [unowned self] in
                // If task canceled, this code should executed before task remove
                guard let identifier = self.taskIdentifierMap[fileURL],
                      let task = self.pendingRequests.first(where: { $0.taskIdentifier == identifier })
                else {
                    return
                }
                if task.error == nil, !task.progress.isFinished, task.progress.isCancelled {
                    tracker.accept(.cancel)
                    if shouldAccessingSecurityScopedResource {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                    if let fileUUID = fileUUID {
                        logger.info("cancel task manual \(fileUUID)")
                        ApiProvider.shared.request(fromApi: CancelUploadRequest(fileUUIDs: [fileUUID]), completionHandler: { _ in })
                    }
                }
            })
        return (task, tracker)
    }

    fileprivate func prepare(fileURL: URL, region _: FlatRegion, targetDirectoryPath: String) -> Observable<UploadInfo> {
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let name = fileURL.lastPathComponent
            let size = (attribute[.size] as? NSNumber)?.intValue ?? 0
            let request = PrepareUploadRequest(fileName: name, fileSize: size, targetDirectoryPath: targetDirectoryPath)
            return ApiProvider.shared.request(fromApi: request)
        } catch {
            return .error(error)
        }
    }

    fileprivate func reportFinish(fileUUID: String, region _: FlatRegion, isWhiteboardProjector _: Bool) -> Observable<Void> {
        ApiProvider.shared.request(fromApi: UploadFinishRequest(fileUUID: fileUUID)).mapToVoid()
    }

    fileprivate func upload(fileURL: URL, info: UploadInfo) throws -> Observable<Void> {
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
            self.taskIdentifierMap[fileURL] = task.taskIdentifier
            self.pendingRequests.append(task)
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
