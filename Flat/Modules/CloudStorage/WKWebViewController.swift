//
//  WKWebViewController.swift
//  Flat
//
//  Created by xuyunshi on 2022/9/20.
//  Copyright © 2022 agora.io. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController {
    var dismissHandler: (()->Void)?
    
    init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        webView.load(URLRequest(url: url))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onClickNaviBack() {
        dismissHandler?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        webView.navigationDelegate = self
        showActivityIndicator()
    }
    
    func setupViews() {
        view.backgroundColor = .color(type: .background)
        webView.backgroundColor = .color(type: .background)
        view.addSubview(webView)
        webView.scrollView.isScrollEnabled = false
        
        if let _ = navigationController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: localizeStrings("Close"), style: .plain, target: self, action: #selector(onClickNaviBack))
            webView.snp.makeConstraints { make in
                make.edges.equalTo(view.safeAreaLayoutGuide)
            }
        } else {
            let closeButton = addPresentCloseButton()
            addPresentTitle(title ?? "")
            webView.snp.makeConstraints { make in
                make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
                make.top.equalTo(closeButton.snp.bottom)
            }
        }
    }

    lazy var webView = WKWebView(frame: .zero)
}

extension WKWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stopActivityIndicator()
    }
}
