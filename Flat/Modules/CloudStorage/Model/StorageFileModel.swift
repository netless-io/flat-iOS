//
//  StorageListModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import Whiteboard

enum StorageCovertStep: String, Codable {
    case none = "None"
    case done = "Done"
    case converting = "Converting"
    case failed = "Failed"
}

enum ResourceType: String, Codable {
    case white = "WhiteboardConvert"
    case projector = "WhiteboardProjector"
    case normal = "NormalResources"
    case directory = "Directory"
}

struct StorageFileModel: Codable, Equatable {
    enum FileType: CaseIterable {
        case img
        case pdf
        case video
        case music
        case ppt
        case word
        case unknown
        case directory

        var iconImageName: String {
            switch self {
            case .directory:
                return "storage_directory"
            case .img:
                return "storage_type_img"
            case .pdf:
                return "storage_type_pdf"
            case .video:
                return "storage_type_video"
            case .music:
                return "storage_type_music"
            case .ppt:
                return "storage_type_ppt"
            case .word:
                return "storage_type_doc"
            case .unknown:
                return "storage_type_doc"
            }
        }

        var availableSuffix: [String] {
            switch self {
            case .img:
                return ["jpg", "jpeg", "png", "webp"]
            case .pdf:
                return ["pdf"]
            case .video:
                return ["mp4"]
            case .music:
                return ["mp3", "aac"]
            case .ppt:
                return ["ppt", "pptx"]
            case .word:
                return ["doc", "docx"]
            case .unknown, .directory:
                return []
            }
        }

        init(fileName: String) {
            self = Self.allCases.first(where: { type in
                for eachSuffix in type.availableSuffix {
                    if fileName.hasSuffix(eachSuffix) {
                        return true
                    }
                }
                return false
            }) ?? .unknown
        }
    }

    struct WhiteboardFilePayload: Codable, Equatable {
        let convertStep: StorageCovertStep
        let region: FlatRegion
        let taskToken: String
        let taskUUID: String
    }

    enum Payload: Codable, Equatable {
        case whiteboardProjector(WhiteboardFilePayload)
        case whiteboardConvert(WhiteboardFilePayload)
        case empty

        var whiteConverteInfo: WhiteboardFilePayload? {
            switch self {
            case let .whiteboardProjector(whiteboardFilePayload):
                return whiteboardFilePayload
            case let .whiteboardConvert(whiteboardFilePayload):
                return whiteboardFilePayload
            case .empty:
                return nil
            }
        }

        enum CodingKeys: String, CodingKey {
            case whiteboardConvert
            case whiteboardProjector
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .whiteboardProjector(payload):
                try container.encode(payload, forKey: .whiteboardProjector)
            case let .whiteboardConvert(payload):
                try container.encode(payload, forKey: .whiteboardConvert)
            case .empty:
                return
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let value = try? container.decode(WhiteboardFilePayload.self, forKey: .whiteboardConvert) {
                self = .whiteboardConvert(value)
                return
            }
            if let value = try? container.decode(WhiteboardFilePayload.self, forKey: .whiteboardProjector) {
                self = .whiteboardProjector(value)
                return
            }
            // Add code here when add new meta type
            self = .empty
        }
    }

    var urlOrEmpty: URL {
        URL(string: fileURL) ?? .init(fileURLWithPath: "")
    }

    let fileURL: String
    let fileUUID: String
    let createAt: Date
    var fileName: String
    let fileSize: Int
    let resourceType: ResourceType
    var meta: Payload

    var fileType: FileType {
        if resourceType == .directory { return .directory }
        return .init(fileName: fileName)
    }

    var fileSizeDescription: String {
        String(format: "%.2fMB", Float(fileSize) / 1024 / 1024)
    }

    var taskType: WhiteConvertTypeV5? {
        ConvertService.convertingTaskTypeFor(url: urlOrEmpty)
    }

    var usable: Bool {
        return !ConvertService.shouldConvertFile(withFile: self)
    }

    var converting: Bool {
        switch meta {
        case .empty: return false
        case let .whiteboardConvert(payload): return payload.convertStep == .converting
        case let .whiteboardProjector(payload): return payload.convertStep == .converting
        }
    }

    mutating func updateConvert(step: StorageCovertStep, taskUUID: String? = nil, taskToken: String? = nil) {
        switch meta {
        case let .whiteboardProjector(whiteboardFilePayload):
            meta = .whiteboardProjector(.init(convertStep: step,
                                              region: whiteboardFilePayload.region,
                                              taskToken: taskToken ?? whiteboardFilePayload.taskToken,
                                              taskUUID: taskUUID ?? whiteboardFilePayload.taskUUID))
        case let .whiteboardConvert(whiteboardFilePayload):
            meta = .whiteboardConvert(.init(convertStep: step,
                                            region: whiteboardFilePayload.region,
                                            taskToken: taskToken ?? whiteboardFilePayload.taskToken,
                                            taskUUID: taskUUID ?? whiteboardFilePayload.taskUUID))
        case .empty:
            return
        }
    }
}
