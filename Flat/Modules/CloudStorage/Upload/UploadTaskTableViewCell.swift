//
//  UploadTaskTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/8.
//  Copyright © 2021 agora.io. All rights reserved.
//

import RxSwift
import UIKit

class UploadTaskTableViewCell: UITableViewCell {
    var progressObserveDisposeBag: DisposeBag?
    var operationClickHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .color(type: .background)
    }

    @IBAction func operationButton(_: Any) {
        operationClickHandler?()
    }

    @IBOutlet var operationButton: UIButton!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var fileNameLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var progressView: UIProgressView!
}
