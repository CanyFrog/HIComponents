//
//  WebViewController.swift
//  HQKit
//
//  Created by HonQi on 6/7/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit
import WebKit

open class WebViewController: UIViewController {
    open override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    /// Public
    open weak var navigationDelegate: WKNavigationDelegate?
    
    open var hasToolBar: Bool = true
    open var hasMoreOptionsButton: Bool = true
    open var hasProgressBar: Bool = true
    open var closeBlock: (()->Void)?
    
    public private(set) var webView: WKWebView!
    public private(set) var contentView: UIView = UIView.hq.autoLayout()
    
    var request: URLRequest?
    
    /// UI
    var navBar = UIView.hq.autoLayout()
    var navBarContent = UIView.hq.autoLayout()
    var toolBar = UIView.hq.autoLayout()
    var toolBarContent = UIView.hq.autoLayout()
    var progressView = UIProgressView.hq.autoLayout()
    
    var moreButton = UIButton.hq.autoLayout()
    var titleLabel = UILabel.hq.autoLayout()
    var backButton = UIButton.hq.autoLayout()
    var forwardButton = UIButton.hq.autoLayout()
    var refreshButton = UIButton.hq.autoLayout()
    var closeButton = UIButton.hq.autoLayout()
    
    var navBarHeight: CGFloat = 46
    var compactNavBarHeight: CGFloat { return UIDevice.current.userInterfaceIdiom == .pad ? 35 : 27 }
    
    var navHeightConstraint: NSLayoutConstraint?
    var toolbarBottomConstraint: NSLayoutConstraint?
    var webViewBootomConstraint: NSLayoutConstraint?
    
    let processPool: WKProcessPool = WKProcessPool()
    
    public convenience init(url: String) {
        self.init(nibName: nil, bundle: nil)
        request = URLRequest(url: URL(string: url)!)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        initializeViews()
        initializeConstrant()
        
        if let request = request {
            webView.load(request)
        }
    }
    
    deinit {
        /// Fix iOS 9 crash
        webView.scrollView.delegate = nil
        
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "canGoForward")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    
    func initializeViews() {
        /// View contains to navbar and content view
        view.addSubview({
          navBar.backgroundColor = UIColor.hq.info
            return navBar
        }())
        
        navBar.addSubview(navBarContent)
        
        navBarContent.addSubview({
            closeButton.setImage(UIImage(named: "icon_close", in: Bundle(for: WebViewController.self), compatibleWith: nil), for: .normal)
            closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
                return closeButton
            }())
        
        navBarContent.addSubview({
            titleLabel.text = self.title
            titleLabel.textColor = UIColor.white
            titleLabel.numberOfLines = 1
            titleLabel.textAlignment = .center
            titleLabel.font = UIFont.systemFont(ofSize: 18)
            return titleLabel
            }())
        
        
        view.addSubview(contentView)
        contentView.addSubview({
            let config = WKWebViewConfiguration()
            config.processPool = processPool
            
            webView = WKWebView(frame: .zero, configuration: config)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.scrollView.delegate = self
            webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
            webView.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
            webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            
            return webView
            }())
        
        contentView.addSubview({
            progressView.trackTintColor = UIColor.clear
            progressView.progressTintColor = UIColor.hq.success
            progressView.isHidden = !self.hasProgressBar
            return progressView
            }())
        
        contentView.addSubview({
            toolBar.isHidden = !self.hasToolBar
            toolBar.backgroundColor = UIColor.hq.info
            return toolBar
            }())
        
        
        toolBar.addSubview(toolBarContent)
        
        toolBarContent.addSubview({
            backButton.setImage(UIImage(named: "icon_back", in: Bundle(for: WebViewController.self), compatibleWith: nil), for: .normal)
            backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
            return backButton
            }())
        
        toolBarContent.addSubview({
            forwardButton.setImage(UIImage(named: "icon_forward", in: Bundle(for: WebViewController.self), compatibleWith: nil), for: .normal)
            forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
            return forwardButton
            }())
        
        toolBarContent.addSubview({
            refreshButton.setImage(UIImage(named: "icon_refresh", in: Bundle(for: WebViewController.self), compatibleWith: nil), for: .normal)
            refreshButton.addTarget(self, action: #selector(refresh), for: .touchUpInside)
            return refreshButton
            }())
        
        toolBarContent.addSubview({
            moreButton.setImage(UIImage(named: "icon_more", in: Bundle(for: WebViewController.self), compatibleWith: nil), for: .normal)
            moreButton.addTarget(self, action: #selector(more), for: .touchUpInside)
            moreButton.isHidden = !hasMoreOptionsButton
            return moreButton
            }())
    }
    
    
    func initializeConstrant() {
        /// View
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            navBarContent.topAnchor.constraint(equalTo: navBar.hq.safeAreaTopAnchor),
            navBarContent.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navBarContent.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navBarContent.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            progressView.topAnchor.constraint(equalTo: contentView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            toolBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        
        
        navHeightConstraint = navBarContent.heightAnchor.constraint(equalToConstant: navBarHeight)
        navHeightConstraint?.isActive = true
        
        webViewBootomConstraint = webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 56)
        webViewBootomConstraint?.isActive = true
        
        toolbarBottomConstraint = toolBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        toolbarBottomConstraint?.isActive = true
        
        /// Navbar
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: navBarContent.topAnchor, constant: 1),
            closeButton.leadingAnchor.constraint(equalTo: navBarContent.leadingAnchor, constant: 2),
            closeButton.bottomAnchor.constraint(equalTo: navBarContent.bottomAnchor, constant: -1),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: navBarContent.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: navBarContent.leadingAnchor, constant: 48),
            titleLabel.trailingAnchor.constraint(equalTo: navBarContent.trailingAnchor, constant: -48)
            ])
        
        
        /// Tool bar
        let hPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 10 : 2
        let vPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 10 : 6
        NSLayoutConstraint.activate([
            toolBarContent.leadingAnchor.constraint(equalTo: toolBar.leadingAnchor),
            toolBarContent.trailingAnchor.constraint(equalTo: toolBar.trailingAnchor),
            toolBarContent.topAnchor.constraint(equalTo: toolBar.topAnchor),
            toolBarContent.bottomAnchor.constraint(equalTo: toolBar.hq.safeAreaBottomAnchor),
            
            backButton.topAnchor.constraint(equalTo: toolBarContent.topAnchor, constant: vPadding),
            backButton.bottomAnchor.constraint(equalTo: toolBarContent.bottomAnchor, constant: -vPadding),
            backButton.leadingAnchor.constraint(equalTo: toolBarContent.leadingAnchor, constant: hPadding),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            forwardButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: hPadding),
            forwardButton.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            forwardButton.heightAnchor.constraint(equalTo: backButton.heightAnchor),
            
            refreshButton.leadingAnchor.constraint(greaterThanOrEqualTo: forwardButton.trailingAnchor, constant: hPadding),
            refreshButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            refreshButton.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            refreshButton.heightAnchor.constraint(equalTo: backButton.heightAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: hasMoreOptionsButton ? moreButton.leadingAnchor : toolBarContent.trailingAnchor, constant: -hPadding),
            
            moreButton.trailingAnchor.constraint(equalTo: toolBarContent.trailingAnchor, constant: -hPadding),
            moreButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            moreButton.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            moreButton.heightAnchor.constraint(equalTo: backButton.heightAnchor),
            ])
    }
    
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let path = keyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context) ;return
        }
        
        if hasProgressBar && path == "estimatedProgress" {
            progressView.isHidden = false
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress >= 1.0 {
                progressView.hq.animated(hidden: true) { [weak self] in
                    self?.progressView.progress = 0.0
                }
            }
        }
        else if (path ==  "canGoBack" || path == "canGoForward") {
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    open func load(url: String) {
        load(request: URLRequest(url: URL(string: url)!))
    }
    
    open func load(request: URLRequest) {
        self.request = request
        webView.load(request)
    }
}


extension WebViewController {
    @objc private func goBack() {
        webView.goBack()
    }
    
    @objc private func goForward() {
        webView.goForward()
    }
    
    @objc private func refresh() {
        progressView.progress = 0
        if let _ = webView.url {
            webView.reload()
        }
        else if let request = request {
            webView.load(request)
        }
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: closeBlock)
    }
    
    @objc private func more() {
        
    }
}

extension WebViewController: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard hasToolBar else { return }
        if velocity.y > 0 && !toolBar.isHidden{
            navBar(compact: true)
            toolBar(hidden: true, animation: true)
        }
        else if velocity.y < 0 && toolBar.isHidden {
            navBar(compact: false)
            toolBar(hidden: false, animation: true)
        }
    }
    
    func navBar(compact: Bool) {
        closeButton.hq.animated(hidden: compact)
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4) {
            let scale = compact ? UIFont.systemFont(ofSize: 14).pointSize / self.titleLabel.font.pointSize : 1.0
            self.titleLabel.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
            self.navHeightConstraint?.constant = compact ? self.compactNavBarHeight : self.navBarHeight
            self.view.layoutIfNeeded()
        }
    }
    
    func toolBar(hidden: Bool, animation: Bool = false) {
        
        guard animation else {
            view.layoutIfNeeded()
            webViewBootomConstraint?.constant = hidden ? 0 : toolBar.hq.height
            toolbarBottomConstraint?.constant = hidden ? toolBar.hq.height : 0
            toolBar.isHidden = hidden
            return
        }
        
        if !hidden { toolBar.isHidden = hidden }
        webViewBootomConstraint?.constant = hidden ? 0 : toolBar.hq.height
        
        view.layoutIfNeeded()
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
            self.toolbarBottomConstraint?.constant = hidden ? self.toolBar.hq.height : 0
            self.view.layoutIfNeeded()
        }) { (_) in
            self.toolBar.isHidden = hidden
        }
    }
}

extension WebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
            completionHandler()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (_) in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (_) in
            completionHandler(true)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)
        
        var text: String?
        alert.addTextField { (textField) in
            textField.text = defaultText
            text = textField.text
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (_) in
            completionHandler(nil)
        }))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (_) in
            completionHandler(text)
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

extension WebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationDelegate == nil else {
            navigationDelegate!.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
            return
        }
        
        if let scheme = navigationAction.request.url?.scheme,
            scheme.hasPrefix("http") && scheme.hasPrefix("file") {
            UIApplication.shared.openURL(navigationAction.request.url!)
            decisionHandler(.cancel)
        }
        else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard navigationDelegate == nil else {
            navigationDelegate!.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
            return
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        navigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        navigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        navigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        navigationDelegate?.webView?(webView, didFinish: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        navigationDelegate?.webView?(webView, didFail: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.serverTrust != nil {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            return
        }
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM {
            promptUserPass(challenge: challenge, protectionSpace: challenge.protectionSpace) { (cred, error) in
                if let c = cred {
                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, c)
                }
                else {
                    completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
                }
            }
        }
        else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        navigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }
    
}

extension WebViewController {
    @available(iOS 11.0, *)
    public func update(cookies: [HTTPCookie], completionHandler: (()->Void)? = nil) {
        var cookies = cookies
        guard !cookies.isEmpty else {
            completionHandler?(); return
        }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let lastCookie = cookies.popLast()
        cookies.forEach{ cookieStore.setCookie($0, completionHandler: nil)}
        cookieStore.setCookie(lastCookie!, completionHandler: completionHandler)
    }
    
    func promptUserPass(challenge: URLAuthenticationChallenge, protectionSpace: URLProtectionSpace, completion: ((URLCredential?, Error?)->Void)?) {
        let credential = challenge.proposedCredential
        
        if let cred = credential,
            let user = cred.user, !user.isEmpty,
            challenge.previousFailureCount == 0 {
            completion?(cred, nil)
            return
        }
        else {
            // show dialog input user and pass
        }
    }
}
