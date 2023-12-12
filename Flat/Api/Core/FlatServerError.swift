//
//  FlatServerError.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/22.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

enum FlatApiError: Int, LocalizedError, CaseIterable {
    case FileCheckFailed = 1_000
    case FileDownloadFailed
    case FileUnzipFailed
    case FileUploadFailed
    
    case ParamsCheckFailed = 100_000
    case ServerFail
    case CurrentProcessFailed
    case NotPermission
    case NeedLoginAgain
    case UnsupportedPlatform
    case JWTSignFailed
    case ExhaustiveAttack
    case RequestSignatureIncorrect
    case NonCompliant
    case UnsupportedOperation

    case SMSVerificationCodeInvalid = 110_000
    case SMSAlreadyExist // Bind when binding already
    case PhoneRegistered // Bind a phone has registered
    case SMSFailedToSendCode // failed to send verification code
    
    case EmailVerificationCodeInvalid = 115_000 // verification code invalid
    case EmailAlreadyExist // email already exist by current user
    case EmailAlreadyBinding // email are binding by other users
    case EmailFailedToSendCode // failed to send verification code
    
    case CensorshipFailed = 120_000 // censorship failed
    
    case OAuthUUIDNotFound = 130_000 // oauth uuid not found
    case OAuthClientIDNotFound  // oauth client id not found
    case OAuthSecretUUIDNotFound  // oauth secret uuid not found

    case RoomNotFound = 200_000
    case RoomIsEnded
    case RoomIsRunning
    case RoomNotIsRunning
    case RoomNotIsEnded
    case RoomNotIsIdle
    case RoomExists // (pmi) room already exists, cannot create new room
    case RoomNotFoundAndIsPmi // room not found and the invite code is pmi

    case PeriodicNotFound = 300_000
    case PeriodicIsEnded
    case PeriodicSubRoomHasRunning

    case UserNotFound = 400_000
    case UserRoomListNotEmpty  // occurs when delete account, user must have quitted all running rooms
    case UserAlreadyBinding // already bound, should unbind first
    case UserPasswordIncorrect // user password (for update) incorrect
    case UserOrPasswordIncorrect // user or password (for login) incorrect
    case UserPmiDrained

    case RecordNotFound = 50000

    case UploadConcurrentLimit = 700_000
    case NotEnoughTotalUsage
    case FileSizeTooBig
    case FileNotFound
    case FileExists
    case DirectoryNotExists // current directory not exists
    case DirectoryAlreadyExists // directory already exists

    case FileIsConverted = 80000
    case FileConvertFailed
    case FileIsConverting
    case FileIsConvertWaiting
    case FileNotIsConvertNone // file convertStep not ConvertStep.None
    case FileNotIsConverting // file convertStep not ConvertStep.Converting

    case LoginGithubSuspended = 90000
    case LoginGithubURLMismatch
    case LoginGithubAccessDenied

    var errorDescription: String? {
        localizeStrings(String(describing: self))
    }
}
