//
//  Decoder+Extension.swift
//  Flat
//
//  Created by xuyunshi on 2021/10/22.
//  Copyright © 2021 agora.io. All rights reserved.
//


import Foundation

fileprivate let defaultFlatDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
}()

fileprivate let defaultNetlessDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

fileprivate let defaultAgoraDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension JSONDecoder {
    static var flatDecoder: JSONDecoder {
        defaultFlatDecoder
    }
    
    static var agoraDecoder: JSONDecoder {
        defaultAgoraDecoder
    }
    
    static var netlessDecoder: JSONDecoder {
        defaultNetlessDecoder
    }
}
