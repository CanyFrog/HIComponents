//
//  ViewController.swift
//  HQDownloadDemo
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit
import HQDownload

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let uri = URL(string: "https://www.apple.com/")
        let request = URLRequest(url: uri!)
        let operation = HQDownloadOperation(request: request, options: [], session: nil)
        let callback = operation.addHandlers(forProgress: { (data, re, ex, url) in
            print(data)
        }) { (error) in
            print("end......................")
        }
        operation.start()
    }

}

