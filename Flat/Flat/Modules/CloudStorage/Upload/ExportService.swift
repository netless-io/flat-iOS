//
//  ExportService.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import AVFoundation

struct VideoConvertService {
    static func convert(url: URL, convertedFileName: String, handler: @escaping ((Result<URL, Error>)->Void)) -> AVAssetExportSession? {
        let asset = AVAsset(url: url)
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        export?.outputFileType = .mp4
        export?.shouldOptimizeForNetworkUse = true
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent(convertedFileName + ".mp4")
        do {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
            }
            export?.outputURL = path
            export?.exportAsynchronously(completionHandler: { [weak export] in
                DispatchQueue.main.async {
                    if let error = export?.error {
                        handler(.failure(error))
                        return
                    }
                    handler(.success(path))
                }
            })
            return export
        }
        catch {
            handler(.failure("error file remove fail"))
            return nil
        }
    }
}
