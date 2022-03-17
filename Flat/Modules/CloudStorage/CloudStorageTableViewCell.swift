//
//  CloudStorageTableViewCell.swift
//  Flat
//
//  Created by xuyunshi on 2021/12/1.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

class CloudStorageTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        backgroundColor = .whiteBG
        contentView.backgroundColor = .whiteBG
        let textStack = UIStackView(arrangedSubviews: [fileNameLabel, sizeAndTimeLabel])
        textStack.axis = .vertical
        textStack.distribution = .fillEqually
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [iconImage, textStack])
        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.distribution = .fill
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        iconImage.snp.makeConstraints { $0.width.equalTo(32) }
        
        contentView.addSubview(convertingActivityView)
        convertingActivityView.snp.makeConstraints { make in
            make.centerX.equalTo(iconImage.snp.right).inset(10)
            make.centerY.equalTo(iconImage.snp.bottom).inset(13)
            make.width.height.equalTo(10)
        }
        convertingActivityView.transform = .init(scaleX: 0.5, y: 0.5)
        
        let line = UIView(frame: .zero)
        line.backgroundColor = .borderColor
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.right.equalTo(stackView)
            make.left.equalTo(textStack)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
        }
    }
    
    func stopConvertingAnimation() {
        convertingActivityView.isHidden = true
        convertingActivityView.stopAnimating()
    }
    
    func startConvertingAnimation() {
        convertingActivityView.isHidden = false
        convertingActivityView.startAnimating()
    }
    
    
    func updateActivityAnimate(_ animate: Bool) {
        if animate {
            if activity.superview == nil {
                contentView.addSubview(activity)
                activity.snp.makeConstraints { make in
                    make.edges.equalTo(iconImage)
                }
            }
            activity.isHidden = false
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
    }

    lazy var convertingActivityView: UIActivityIndicatorView = {
        let view: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: .gray)
        }
        view.color = .brandColor
        return view
    }()
    
    lazy var activity: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()
    
    lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var sizeAndTimeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .subText
        return label
    }()
    
    lazy var fileNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14)
        label.textColor = .text
        return label
    }()
}
