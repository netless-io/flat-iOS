//
//  ClassRoomRTMDelegate.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/21.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

protocol ClassRoomRtmDelegate: AnyObject {
    func classRoomRtm(_ rtm: ClassRoomRtm, error: Error)
    
    func classRoomRtmDidReceiveCommand(_ rtm: ClassRoomRtm, command: RtmCommand, senderId: String)
    
    func classRoomRtmDidReceiveMessage(_ rtm: ClassRoomRtm, message: UserMessage)
    
    func classRoomRtmMemberJoined(_ rtm: ClassRoomRtm, memberUserId: String)
    
    func classRoomRtmMemberLeft(_ rtm: ClassRoomRtm, memberUserId: String)
}
