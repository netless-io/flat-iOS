//
//  AnyPreview.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation
import QuickLook

class AnyPreview: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?
    init(previewItemURL: URL, title: String) {
        self.previewItemURL = previewItemURL
        previewItemTitle = title
    }
}
