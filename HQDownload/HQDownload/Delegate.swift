//
//  Delegate.swift
//  HQDownload
//
//  Created by Magee Huang on 7/3/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation

class Delegate: NSObject {
    var operators = NSPointerArray.weakObjects()
    
    var isEmpty: Bool {
        operators.compact()
        return operators.count <= 0
    }
    
    func forEach(_ transform: (Operator)->Void) {
        operators.compact()
        operators.allObjects.forEach { (obj) in
            if let op = obj as? Operator {
                transform(op)
            }
        }
    }
}

extension Delegate: URLSessionDataDelegate {
    
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
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // notify all isinvalid
    }
}
