//
//  ConvertService.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/23.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

private enum ConvertConfig {
    static let staticConvertPathExtensions: [String] = ["pdf", "ppt", "doc", "docx"]

    static let dynamicConvertPathExtensions: [String] = ["pptx"]

    static let shouldConvertPathExtensions: [String] = staticConvertPathExtensions + dynamicConvertPathExtensions
}

enum ConvertService {
    static func isDynamicPpt(url: URL) -> Bool {
        ConvertConfig.dynamicConvertPathExtensions.contains(url.pathExtension.lowercased())
    }

    static func convertingTaskTypeFor(url: URL) -> WhiteConvertTypeV5? {
        let ext = url.pathExtension.lowercased()
        if ConvertConfig.staticConvertPathExtensions.contains(ext) {
            return .static
        } else if ConvertConfig.dynamicConvertPathExtensions.contains(ext) {
            return .dynamic
        }
        return nil
    }

    static func isFileConvertible(withFileURL url: URL) -> Bool {
        ConvertConfig.shouldConvertPathExtensions.contains(url.pathExtension.lowercased())
    }

    static func shouldConvertFile(withFile file: StorageFileModel) -> Bool {
        if let payload = file.meta.whiteConverteInfo,
           payload.convertStep == .none,
           ConvertConfig.shouldConvertPathExtensions.contains(file.urlOrEmpty.pathExtension.lowercased())
        {
            return true
        }
        return false
    }

    static func startConvert(fileUUID: String,
                             completion: @escaping ((Result<StartConvertRequest.Result, Error>) -> Void))
    {
        ApiProvider.shared.request(fromApi: StartConvertRequest(fileUUID: fileUUID)) { result in
            switch result {
            case let .success(item):
                logger.info("submit convert task success")
                completion(.success(item))
            case let .failure(error):
                logger.info("submit convert task error \(error)")
                completion(.failure(error))
            }
        }
    }
}
