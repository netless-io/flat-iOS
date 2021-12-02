//
//  PageListContainer.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class PageListContainer<T> {
    var itemsUpdateHandler: (([T], Bool)->Void)?
    
    var items: [T]
    var currentPage: Int
    var canLoadMore: Bool
    
    fileprivate let maxItemsPerPage: Int = 50
    
    func appendResult(items: [T], fromPage page: Int) {
        if page == 1 {
            self.currentPage = page
            self.canLoadMore = items.count >= maxItemsPerPage
            self.items = items
        } else {
            // Is Next page
            if self.currentPage + 1 == page {
                self.currentPage = page
                self.canLoadMore = items.count >= maxItemsPerPage
                self.items.append(contentsOf: items)
            }
        }
        itemsUpdateHandler?(self.items, self.canLoadMore)
    }
    
    init() {
        items = []
        currentPage = 1
        canLoadMore = false
    }
}
