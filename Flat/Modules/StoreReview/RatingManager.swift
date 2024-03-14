//
//  RatingManager.swift
//  Flat
//
//  Created by xuyunshi on 2023/3/16.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation
import StoreKit

struct RatingManager {
    struct RatingContext {
        let enterClassroomDuration: TimeInterval
    }

    struct RatingRecord: Codable {
        let date: Date
        let version: String
    }

    static let minimalEnterClassroomDuration = TimeInterval(60 * 10)
    static let minimalReviewActionDay = 3
    static let recordKey = "io.agora.flat.ratingRecord"
    static func getStoredRatingRecord() -> [RatingRecord] {
        if let data = UserDefaults.standard.data(forKey: recordKey) {
            do {
                let records = try JSONDecoder().decode([RatingRecord].self, from: data)
                return records
            }
            catch {
                globalLogger.error("decode rating records error \(error)")
            }
        }
        return []
    }

    static func update(storedRecords: [RatingRecord]) {
        do {
            let data = try JSONEncoder().encode(storedRecords)
            UserDefaults.standard.set(data, forKey: recordKey)
        }
        catch {
            globalLogger.error("encode rating records error \(error)")
        }
    }
    
    static var ratingRecords: [RatingRecord] = getStoredRatingRecord()
    
    @available(iOS 14.0, *)
    static func requestReviewIfAppropriate(context: RatingContext) {
        guard context.enterClassroomDuration >= minimalEnterClassroomDuration else { return }
        let date = Date()
        if let latestRecord = ratingRecords.last {
            // Check minimal action day
            let components = Calendar.current.dateComponents([.day], from: latestRecord.date, to: date)
            guard let day = components.day, day >= minimalReviewActionDay else { return }
            // Check version
            guard latestRecord.version != Env().version else { return }
        }
        // Perform rating prompt
        ratingRecords.append(.init(date: date, version: Env().version))
        update(storedRecords: ratingRecords)
        let connectedWindowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        if let activeScene = connectedWindowScenes.first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: activeScene)
        }
    }
}
