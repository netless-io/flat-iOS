//
//  ConvertConfig.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/10.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

struct ConvertConfig {
    static var staticConvertPathExtensions: [String] = ["pdf", "ppt", "doc", "docx"]
    
    static var dynamicConvertPathExtensions: [String] = ["pptx"]
    
    static var shouldConvertPathExtensions: [String] = {
        return staticConvertPathExtensions + dynamicConvertPathExtensions
    }()
    
}
