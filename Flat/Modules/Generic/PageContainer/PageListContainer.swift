//
//  PageListContainer.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import Foundation

class PageListContainer<T> {
    var itemsUpdateHandler: (([T], Bool) -> Void)?

    var items: [T]
    var currentPage: Int
    var canLoadMore: Bool

    private let maxItemsPerPage: Int = 50

    func receive(items: [T], withItemsPage page: Int) {
        if page == 1 {
            currentPage = page
            canLoadMore = items.count >= maxItemsPerPage
            self.items = items
        } else {
            // Is Next page
            if currentPage + 1 == page {
                currentPage = page
                canLoadMore = items.count >= maxItemsPerPage
                self.items.append(contentsOf: items)
            }
        }
        itemsUpdateHandler?(self.items, canLoadMore)
    }

    init() {
        items = []
        currentPage = 1
        canLoadMore = false
    }
}
