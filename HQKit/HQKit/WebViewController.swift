//
//  WebViewController.swift
//  HQKit
//
//  Created by Magee Huang on 6/7/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit
import WebKit

open class WebViewController: UIViewController {
    open weak var navigationDelegate: WKNavigationDelegate?
    open var hasToolBar: Bool = true
    open var hasMoreOptionsButton: Bool = true
    open var hasProgressBar: Bool = true
    open var closeBlock: (()->Void)?
    
    public private(set) var webView: WKWebView!
    public private(set) var contentView: UIView = UIView.hq.autoLayout()
    
    var request: URLRequest?
    var navBar = UIView.hq.autoLayout()
    var toolBar = UIView.hq.autoLayout()
    var toolBarContentView = UIView.hq.autoLayout()
    var progressView = UIProgressView.hq.autoLayout()
    var optionsStackView: UIStackView?
    var transparentView: UIView?
    
    var titleLabel: UILabel?
    var backButton: UIButton?
    var forwardButton: UIButton?
    var refreshButton: UIButton?
    var closeButton: UIButton?
    var moreButton: UIButton?
    
    var navBarHeight: CGFloat = 44
    var compactNavBarHeight: CGFloat = 28
    
    var navHeightConstraint: NSLayoutConstraint?
    var toolbarBottomConstraint: NSLayoutConstraint?
    var webViewBootomConstraint: NSLayoutConstraint?
    
    let processPool: WKProcessPool = WKProcessPool()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        initializeViews()
        
        webView?.load(request!)
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
        view.addSubview(navBar)
        navBar.addSubview({
            closeButton = UIButton(type: .contactAdd)
            closeButton!.hq.addEvent({ [weak self] in
                self?.dismiss(animated: true, completion: nil)
                self?.closeBlock?()
                }, .touchUpInside)
                return closeButton!
            }())
        
        navBar.addSubview({
            titleLabel = UILabel()
            titleLabel?.text = self.title
            // font color
            return titleLabel!
            }())
        
        
        view.addSubview(contentView)
        contentView.addSubview({
            let config = WKWebViewConfiguration()
            config.processPool = processPool
            
            webView = WKWebView(frame: .zero, configuration: config)
            webView?.translatesAutoresizingMaskIntoConstraints = false
            webView?.uiDelegate = self
            webView?.navigationDelegate = self
            webView?.scrollView.delegate = self
            webView?.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
            webView?.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
            webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
            
            return webView!
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
        
        
        toolBar.addSubview(toolBarContentView)
        
        toolBarContentView.addSubview({
            backButton = UIButton(type: .contactAdd)
            backButton!.hq.addEvent({ [weak self] in
                self?.webView.goBack()
            }, .touchUpInside)
            return backButton!
            }())
        
        toolBarContentView.addSubview({
            forwardButton = UIButton(type: .custom)
            forwardButton!.hq.addEvent({ [weak self] in
                self?.webView.goForward()
            }, .touchUpInside)
            return forwardButton!
            }())
        
        toolBarContentView.addSubview({
            refreshButton = UIButton(type: .contactAdd)
            refreshButton!.hq.addEvent({[weak self] in
                self?.progressView.progress = 0
                if let _ = self?.webView.url {
                    self?.webView.reload()
                }
                else if let request = self?.request {
                    self?.webView.load(request)
                }
            }, .touchUpInside)
            return refreshButton!
            }())
        
        toolBarContentView.addSubview({
            moreButton = UIButton(type: .contactAdd)
            
            return moreButton!
            }())
        
        
    }
    
    
    func initializeConstrant() {
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
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
            
            toolBarContentView.leadingAnchor.constraint(equalTo: toolBar.leadingAnchor),
            toolBarContentView.trailingAnchor.constraint(equalTo: toolBar.trailingAnchor),
            toolBarContentView.topAnchor.constraint(equalTo: toolBar.topAnchor),
            toolBarContentView.bottomAnchor.constraint(equalTo: toolBar.hq.safeAreaBottomAnchor),
            ])
        
        
        navHeightConstraint = navBar.heightAnchor.constraint(equalToConstant: 44)
        navHeightConstraint?.isActive = true
        
        webViewBootomConstraint = webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 56)
        webViewBootomConstraint?.isActive = true
        
        toolbarBottomConstraint = toolBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        toolbarBottomConstraint?.isActive = true
        
        /// navbar subviews
        let navViews = ["close": closeButton!, "title": titleLabel!]
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-1-[close(44)]-1-|", options: .init(rawValue: 0), metrics: nil, views:navViews)
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[close(44)]-2-[title]-48-|", options: .init(rawValue: 0), metrics: nil, views: navViews)
    }
    
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let path = keyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context) ;return
        }
        
        if hasProgressBar && path == "estimatedProgress" {
            progressView.isHidden = false
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress > 1.0 {
                progressView.hq.animated(hidden: true) { [weak self] in
                    self?.progressView.progress = 0.0
                }
            }
        }
        else if (path ==  "canGoBack" || path == "canGoForward") {
            backButton?.isEnabled = webView.canGoBack
            forwardButton?.isEnabled = webView.canGoForward
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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
        closeButton?.hq.animated(hidden: compact)
        if compact {
            NSLayoutConstraint.deactivate((closeButton?.constraints)!)
        }
        else {
            NSLayoutConstraint.activate((closeButton?.constraints)!)
        }
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4) {
            let scale = compact ? UIFont.systemFont(ofSize: 12).pointSize / self.titleLabel!.font.pointSize : 1.0
            self.titleLabel?.transform = CGAffineTransform().scaledBy(x: scale, y: scale)
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
