//
//  SessionUtil.swift
//  HQDownload
//
//  Created by HonQi on 7/3/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

class SessionUtil: NSObject {
    var operators = NSPointerArray.weakObjects()
    var isEmpty: Bool {
        operators.compact()
        return operators.count <= 0
    }
    
    let session: URLSession
    
    init(options: OptionsInfo) {
        super.init()
//        var config = URLSessionConfiguration.background(withIdentifier: <#T##String#>)
        // https://www.jianshu.com/p/1211cf99dfc3
        
        var config = URLSessionConfiguration.background(withIdentifier: "me.HonQi.Download.BackgroundTask")
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    func addDelegateObserver(ob: Downloader) {
        operators.hq.addObject(ob)
    }
    
    func createDataRequest(request: URLRequest) -> URLSessionDataTask {
        return session.dataTask(with: request)
    }
}


/// Util function
extension SessionUtil {
    func forEach(_ transform: (Downloader)->Void) {
        operators.compact()
        operators.allObjects.forEach { (obj) in
            if let op = obj as? Downloader {
                transform(op)
            }
        }
    }
    
    func contains(_ url: URL) -> Downloader? {
        operators.compact()
        let ops = operators.allObjects.filter { (obj) -> Bool in
            return (obj as? Downloader)?.dataTask?.originalRequest?.url == url
        }
        return ops.last as? Downloader
    }
}


extension SessionUtil: URLSessionDataDelegate {
    
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard !isEmpty else {
            completionHandler(.cancel)
            return
        }
        
        forEach {
            if $0.dataTask?.taskIdentifier == dataTask.taskIdentifier {
                let disposition = $0.receive(response: response)
                completionHandler(disposition)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        forEach {
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
        
        forEach {
            if $0.dataTask?.taskIdentifier == dataTask.taskIdentifier {
                let cached = $0.cachedResponse()
                completionHandler(cached ? proposedResponse : nil)
            }
        }
    }

    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        forEach {
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
        
        forEach {
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
