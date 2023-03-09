//
//  CGImage+isDark.swift
//  Flat
//
//  Created by xuyunshi on 2023/2/23.
//  Copyright © 2023 agora.io. All rights reserved.
//

import Foundation

extension CGImage {
    var isBlack: Bool {
        guard let imageData = dataProvider?.data else { return false }
        guard let ptr = CFDataGetBytePtr(imageData) else { return false }
        let length = CFDataGetLength(imageData)
        let by = length / 28
        for i in stride(from: 0, to: length, by: by) {
            let r = ptr[i]
            let g = ptr[i + 1]
            let b = ptr[i + 2]
            if r != 0 || g != 0 || b != 0 {
                return false
            }
        }
        return true
    }

    func resize(size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        let bytesPerPixel = bitsPerPixel / bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel

        guard let colorSpace = colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}
