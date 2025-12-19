//
//  CaptchaWebViewController.swift
//  Flat
//
//  Created by Codex on 2025/12/18.
//

import UIKit
import SnapKit
import WebKit

final class CaptchaWebViewController: UIViewController {
    private enum Constants {
        static let messageHandlerName = "getCaptchaVerifyParam"
        static let readyMessageHandlerName = "captchaReady"
    }

    var usingClose = true
    var dismissHandler: (() -> Void)?

    /// Receives messages posted from JS via `window.webkit.messageHandlers.getCaptchaVerifyParam.postMessage(...)`.
    var onCaptchaMessage: ((Any) -> Void)?

    private let isScrollEnabled: Bool
    private let captchaRegion: String
    private let captchaPrefix: String
    private let captchaSceneId: String
    private var hasStoppedLoading = false

    private var presentCloseButton: UIButton?
    private var presentTitleLabel: UILabel?

    init(title: String? = nil, isScrollEnabled: Bool = false) {
        self.isScrollEnabled = isScrollEnabled
        let env = Env()
        self.captchaRegion = env.aliyunCaptchaRegion.isEmpty ? (env.region == .CN ? "cn" : "sgp") : env.aliyunCaptchaRegion
        self.captchaPrefix = env.aliyunCaptchaPrefix
        self.captchaSceneId = env.aliyunCaptchaSceneId
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        webView.navigationDelegate = self
        view.startFlatLoading()
        loadCaptchaHTML()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presentCloseButton?.removeFromSuperview()
        presentTitleLabel?.removeFromSuperview()

        if navigationController != nil {
            if usingClose {
                navigationItem.leftBarButtonItem = UIBarButtonItem(
                    title: localizeStrings("Close"),
                    style: .plain,
                    target: self,
                    action: #selector(onClickNaviBack)
                )
            }
            webView.snp.remakeConstraints { make in
                make.edges.equalTo(view.safeAreaLayoutGuide)
            }
        } else {
            presentCloseButton = addPresentCloseButton()
            presentTitleLabel = addPresentTitle(title ?? "")
            webView.snp.remakeConstraints { make in
                make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
                make.top.equalTo(presentCloseButton!.snp.bottom)
            }
        }
    }

    @objc private func onClickNaviBack() {
        if let dismissHandler {
            dismissHandler()
        } else {
            dismiss(animated: true)
        }
    }

    private func setupViews() {
        view.backgroundColor = .color(type: .background)
        webView.backgroundColor = .color(type: .background)
        webView.scrollView.isScrollEnabled = isScrollEnabled
        view.addSubview(webView)
    }

    private func loadCaptchaHTML() {
        guard let url = Bundle.main.url(forResource: "captcha", withExtension: "html") else {
            view.endFlatLoading()
            toast("Captcha web file not found: captcha.html")
            return
        }
        loadLocalFileURL(url)
    }

    private func loadLocalFileURL(_ url: URL) {
        let accessURL = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: accessURL)
    }

    private lazy var webView: WKWebView = {
        func escapeForJavaScriptSingleQuote(_ value: String) -> String {
            value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
        }

        let javascript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta)";
        let userScript = WKUserScript(source: javascript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let region = escapeForJavaScriptSingleQuote(captchaRegion)
        let prefix = escapeForJavaScriptSingleQuote(captchaPrefix)
        let sceneId = escapeForJavaScriptSingleQuote(captchaSceneId)
        let language = escapeForJavaScriptSingleQuote(LocaleManager.language == .Chinese ? "cn" : "en")
        let captchaConfigJS = """
        window.AliyunCaptchaConfig = window.AliyunCaptchaConfig || {};
        window.AliyunCaptchaConfig.region = '\(region)';
        window.AliyunCaptchaConfig.prefix = '\(prefix)';
        window.AliyunCaptchaSceneId = '\(sceneId)';
        window.AliyunCaptchaLanguage = '\(language)';
        """
        let captchaConfigScript = WKUserScript(source: captchaConfigJS, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(captchaConfigScript)
        userContentController.addUserScript(userScript)
        userContentController.add(self, name: Constants.messageHandlerName)
        userContentController.add(self, name: Constants.readyMessageHandlerName)

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController

        let view = WKWebView(frame: .zero, configuration: config)
        if #available(iOS 16.4, *) {
            view.isInspectable = true
        }
        return view
    }()
}

extension CaptchaWebViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        // Wait for captcha ready message to stop loading
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        stopLoadingOnce()
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        stopLoadingOnce()
    }
}

extension CaptchaWebViewController: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case Constants.messageHandlerName:
            onCaptchaMessage?(message.body)
        case Constants.readyMessageHandlerName:
            stopLoadingOnce()
        default:
            break
        }
    }
}

private extension CaptchaWebViewController {
    func stopLoadingOnce() {
        guard !hasStoppedLoading else { return }
        hasStoppedLoading = true
        view.endFlatLoading()
    }
}
