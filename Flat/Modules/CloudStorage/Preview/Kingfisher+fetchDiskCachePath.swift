//
//  Kingfisher+fetchDiskCachePath.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Kingfisher
import Foundation

extension KingfisherManager {
    func retrieveImageDiskCachePath(fromURL url: URL, handler: @escaping (Result<String, Error>)->Void) {
        let source = Kingfisher.Source.network(url)
        let isCache = KingfisherManager.shared.cache.isCached(forKey: source.cacheKey)
        let path = KingfisherManager.shared.cache.cachePath(forKey: source.cacheKey)
        if isCache {
            handler(.success(path))
        } else {
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success:
                    KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: source.cacheKey) { cacheResult in
                        switch cacheResult {
                        case .success:
                            handler(.success(path))
                        case .failure(let error):
                            handler(.failure(error))
                        }
                    }
                case .failure(let error):
                    handler(.failure(error))
                }
            }
        }
    }
}
