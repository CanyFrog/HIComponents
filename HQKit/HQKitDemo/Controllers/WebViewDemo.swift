//
//  WebViewDemo.swift
//  HQKitDemo
//
//  Created by HonQi Huang on 6/11/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQKit

class WebViewDemo: BaseDemo {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let BaiduBtn = initBtn(title: "BAIDU")
        BaiduBtn.hq.addEvent({
            let web = WebViewController(url: "https://www.baidu.com")
            web.title = self.title
            self.present(web, animated: true, completion: nil)
        }, .touchUpInside)
        
        BaiduBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        BaiduBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
