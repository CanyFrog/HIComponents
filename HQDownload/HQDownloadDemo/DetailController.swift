//
//  DetailController.swift
//  HQDownloadDemo
//
//  Created by Qi on 2018/4/20.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit

class DetailController: UIViewController, URLSessionDataDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: URL(string: "https://httpbin.org/bytes/4194304")!)
        request.httpMethod = "HEAD"
        session.dataTask(with: request).resume()
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("received response")
        print(response)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("received data")
        print(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completeion")
        print(error.debugDescription)
    }
}
