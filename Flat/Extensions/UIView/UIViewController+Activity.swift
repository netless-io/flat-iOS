//
//  UIViewController+Activity.swift
//  flat
//
//  Created by xuyunshi on 2021/10/14.
//  Copyright © 2021 agora.io. All rights reserved.
//

import UIKit

extension UIView {
    @discardableResult
    func showActivityIndicator(text: String? = nil,
                               forSeconds seconds: TimeInterval = 0) -> CustomActivityIndicatorView
    {
        activityView.textLabel.text = text
        activityView.startAnimating()
        activityView.setNeedsLayout()
        if seconds > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.stopActivityIndicator()
            }
        }
        return activityView
    }

    func stopActivityIndicator() {
        activityView.stopAnimating()
    }

    fileprivate var activityView: CustomActivityIndicatorView {
        let activityViewTag = 999
        let activityView: CustomActivityIndicatorView
        if let view = viewWithTag(activityViewTag) as? CustomActivityIndicatorView {
            activityView = view
        } else {
            let view: CustomActivityIndicatorView
            view = CustomActivityIndicatorView(style: .large)
            view.color = .white
            activityView = view
            addSubview(activityView)
            activityView.center = center
            activityView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            activityView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            activityView.tag = activityViewTag
        }
        bringSubviewToFront(activityView)
        return activityView
    }
}

extension UIViewController {
    @discardableResult
    func showActivityIndicator(text: String? = nil,
                               forSeconds seconds: TimeInterval = 0) -> CustomActivityIndicatorView
    {
        activityView.textLabel.text = text
        activityView.startAnimating()
        activityView.setNeedsLayout()
        if seconds > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.stopActivityIndicator()
            }
        }
        return activityView
    }

    func stopActivityIndicator() {
        activityView.stopAnimating()
    }

    fileprivate var activityView: CustomActivityIndicatorView {
        let activityViewTag = 999
        let activityView: CustomActivityIndicatorView
        if let view = view.viewWithTag(activityViewTag) as? CustomActivityIndicatorView {
            activityView = view
        } else {
            let view: CustomActivityIndicatorView
            view = CustomActivityIndicatorView(style: .large)
            view.color = .white
            activityView = view
            self.view.addSubview(activityView)
            activityView.center = self.view.center
            activityView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            activityView.snp.makeConstraints {
                // To avoid layout constraints conflict with some vc's view as a child vc.
                $0.edges.equalToSuperview().priority(.low)
            }
            activityView.tag = activityViewTag
        }
        view.bringSubviewToFront(activityView)
        return activityView
    }
}

class CustomActivityIndicatorView: UIActivityIndicatorView {
    override init(style: UIActivityIndicatorView.Style) {
        super.init(style: style)
        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError()
    }

    func setupViews() {
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(40)
        }
    }

    lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.text = nil
        return label
    }()
}
