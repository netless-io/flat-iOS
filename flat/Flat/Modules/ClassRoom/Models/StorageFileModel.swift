//
//  StorageListModel.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum StorageCovertStep: String, Codable {
    case none = "None"
    case done = "Done"
    case converting = "Converting"
    case failed = "Failed"
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
        
        var iconImageName: String {
            switch self {
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
            case .unknown:
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
    
    var convertStep: StorageCovertStep
    let createAt: Date
    let external: Bool
    var fileName: String
    let fileSize: Int
    var fileType: FileType { .init(fileName: fileName) }
    var fileSizeDescription: String {
        String(format: "%.2fMB", Float(fileSize) / 1024 / 1024)
    }
    
    var taskType: ConversionTaskType? {
        ConvertService.convertingTaskTypeFor(url: fileURL)
    }
    
    var usable: Bool {
        return !ConvertService.shouldConvertFile(withFile: self)
    }
    let fileURL: URL
    let fileUUID: String
    let region: Region
    var taskToken: String
    var taskUUID: String
}
