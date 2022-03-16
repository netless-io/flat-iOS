//
//  ShareManager.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/24.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct ShareManager {
    static func createShareActivityViewController(
        roomUUID: String,
        beginTime: Date,
        title: String,
        roomNumber: String
    ) -> UIViewController {
        let link = Env().webBaseURL + "/join/\(roomUUID)"
        let linkURL = URL(string: link)!
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let timeStr  = NSLocalizedString("Start Time", comment: "") + ": " + formatter.string(from: beginTime)
        let subStr = (NSLocalizedString("Room Subject", comment: "")) + ": " + title
        let numStr = NSLocalizedString("Room Number", comment: "") + ": " + roomNumber
        let des =  numStr + "\n" + timeStr + "\n" + subStr
        let vc = UIActivityViewController(activityItems: [linkURL, des], applicationActivities: nil)
        
        vc.excludedActivityTypes = [
            .airDrop,
            .mail,
            .addToReadingList
        ]
        return vc
    }
}
