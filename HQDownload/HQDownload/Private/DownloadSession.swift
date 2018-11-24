//
//  Session.swift
//  HQDownload
//
//  Created by HonQi on 7/3/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

class Session: NSObject {
    var options: OptionsInfo!
    
    /// Dwonloader
    var downloaders = NSPointerArray.weakObjects()
    var isEmpty: Bool {
        downloaders.compact()
        return downloaders.count <= 0
    }
    
    
    /// Callback
    typealias Event = (URL, DownloadClosure.Event) -> Void
    lazy var eventsMap = InnerKeyMap<Event>()
    lazy var eventsLock = DispatchSemaphore(value: 1)
    
    
    /// Session
    let session: URLSession
    var dataTask: URLSessionDataTask?
    var downloadTask: URLSessionDownloadTask?
    
    
    
    init(options: OptionsInfo) {
        super.init()
        self.options = options
//        var config = URLSessionConfiguration.background(withIdentifier: <#T##String#>)
        // https://www.jianshu.com/p/1211cf99dfc3
        
//        var config = URLSessionConfiguration.background(withIdentifier: "me.HonQi.Download.BackgroundTask")
//        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    
    func createDataRequest(request: URLRequest) -> URLSessionDataTask {
        return session.dataTask(with: request)
    }
}


/// Callback Util
extension Session: Eventable {
//    @discardableResult
//    func subscribe(_ events: DownloadClosure ...) -> UInt64 {
//        let event: Event = { (url, event) in
//            events.forEach { $0.trigger(url: url, event: event) }
//        }
//        
//        return Lock.semaphore(eventsLock) { () -> UInt64 in
//            return eventsMap.insert(event)
//        }
//    }
    
    @discardableResult
    func subscribe(url: URL, _ events: DownloadClosure ...) -> UInt64 {
        let event: Event = { (source, event) in
            guard source == url else { return }
            events.forEach { $0.trigger(url: source, event: event) }
        }
        
        return Lock.semaphore(eventsLock) { () -> UInt64 in
            return eventsMap.insert(event)
        }
    }
    
    func unsubscribe(_ key: UInt64) {
        Lock.semaphore(eventsLock) {
            eventsMap.remove(key)
        }
    }
    
    func trigger( _ url: URL, _ event: DownloadClosure.Event) {
        DispatchQueue.main.async {
            self.eventsMap.forEach({ (wrap) in
                wrap(url, event)
            })
        }
    }
}



/// Downloader Util
extension Session {
    func registerDownloader(dl: Downloader) {
        downloaders.hq.addObject(dl)
    }
    
    func downloaderMap(_ transform: (Downloader)->Void) {
        downloaders.compact()
        downloaders.allObjects.forEach { (obj) in
            if let op = obj as? Downloader {
                transform(op)
            }
        }
    }
    
//    func contains(_ url: URL) -> Downloader? {
//        downloaders.compact()
//        let ops = downloaders.allObjects.filter { (obj) -> Bool in
//            return (obj as? Downloader)?.dataTask?.originalRequest?.url == url
//        }
//        return ops.last as? Downloader
//    }
}




// MARK: - SessionDelegate
extension Session: URLSessionTaskDelegate {
    private func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust { // method is trust server
            if options.allowInvalidSSLCert {
                // when authenticationMethod is ServerTrust, must be not nil
                completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
                return
            }
            // TODO: allow trust host
        }
        
        if let cred = options.urlCredential, challenge.previousFailureCount == 0 { // previos never failure
            completionHandler(.useCredential, cred)
            return
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
}


extension Session: URLSessionDataDelegate {
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard !isEmpty, let request = dataTask.originalRequest ?? dataTask.currentRequest else {
            completionHandler(.cancel)
            return
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let code = statusCode,
            (200..<400).contains(code) else {
                trigger(request.url!, .error(.statusCodeInvalid(statusCode ?? 404)))
                completionHandler(.cancel)
                return
        }
        
        if code == 304,
            (session.configuration.urlCache ?? URLCache.shared).cachedResponse(for: request)?.data == nil
        {
            // '304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data
            // URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
            trigger(request.url!, .error(.noCache304))
            completionHandler(.cancel)
            return
        }
        
        let size = response.expectedContentLength
        
        var name: String! = options.fileName
        if name == nil {
            name = (response.suggestedFilename ?? request.url?.lastPathComponent) ?? UUID().uuidString
            options.append(.fileName(name))
        }
        
//        openStream(fileName: name)
//        progress = Progress(totalUnitCount: size)
        trigger(request.url!, .start(name, size))
        completionHandler(.allow)
        
//        downloaderMap {
//            if $0.dataTask?.taskIdentifier == dataTask.taskIdentifier {
//                let disposition = $0.receive(response: response)
//                completionHandler(disposition)
//            }
//        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloaderMap {
            if $0.dataTask?.taskIdentifier == dataTask.taskIdentifier {
                $0.receive(data: data)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        guard !isEmpty else {
            completionHandler(proposedResponse)
            return
        }
        
        downloaderMap {
            if $0.dataTask?.taskIdentifier == dataTask.taskIdentifier {
                let cached = $0.cachedResponse()
                completionHandler(cached ? proposedResponse : nil)
            }
        }
    }

    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        downloaderMap {
            if $0.dataTask?.taskIdentifier == task.taskIdentifier {
                $0.complete(error: error)
            }
        }
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard !isEmpty else {
            completionHandler(.performDefaultHandling, nil) //
            return
        }
        
        downloaderMap {
            if $0.dataTask?.taskIdentifier == task.taskIdentifier {
                let cred = $0.receive(challenge: challenge)
                completionHandler(cred.0, cred.1)
            }
        }
    }
    
    
    /// All task completed
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
}
