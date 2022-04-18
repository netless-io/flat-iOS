//
//  FlatServerError.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum FlatApiError: Int, LocalizedError {
    case ParamsCheckFailed = 100000
    case ServerFail
    case CurrentProcessFailed
    case NotPermission
    case NeedLoginAgain
    case UnsupportedPlatform
    case JWTSignFailed
    
    case PhoneRegistered = 110002
    
    case RoomNotFound = 200000
    case RoomIsEnded
    case RoomIsRunning
    case RoomNotIsRunning
    case RoomNotIsEnded
    case RoomNotIsIdle
    
    case PeriodicNotFound = 300000
    case PeriodicIsEnded
    case PeriodicSubRoomHasRunning
    
    case UserNotFound = 400000
    
    case RecordNotFound = 50000
    
    case UploadConcurrentLimit = 700000
    case NotEnoughTotalUsage
    case FileSizeTooBig
    case FileNotFound
    case FileExists
    
    case FileIsConverted = 80000
    case FileConvertFailed
    case FileIsConverting
    case FileIsConvertWaiting
    
    case LoginGithubSuspended = 90000
    case LoginGithubURLMismatch
    case LoginGithubAccessDenied
    
    var errorDescription: String? {
        NSLocalizedString(String(describing: self), comment: "")
    }
}
