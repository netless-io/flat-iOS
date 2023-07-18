//
//  Region.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/24.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Fastboard
import Foundation
import Whiteboard

enum FlatRegion: String, Codable {
    case CN_HZ = "cn-hz"
    case US_SV = "us-sv"
    case SG = "sg"
    case IN_MUM = "in-mum"
    case GB_LON = "gb-lon"
    case none
}

extension FlatRegion {
    func toFastRegion() -> Region {
        let region: Region
        switch self {
        case .CN_HZ:
            region = .CN
        case .US_SV:
            region = .US
        case .SG:
            region = .SG
        case .IN_MUM:
            region = .IN
        case .GB_LON:
            region = .GB
        case .none:
            region = .CN
        }
        return region
    }

    func toWhiteRegion() -> WhiteRegionKey {
        let region: WhiteRegionKey
        switch self {
        case .CN_HZ:
            region = .CN
        case .US_SV:
            region = .US
        case .SG:
            region = .SG
        case .IN_MUM:
            region = .IN
        case .GB_LON:
            region = .GB
        case .none:
            region = .CN
        }
        return region
    }
}
