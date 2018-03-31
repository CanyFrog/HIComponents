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
        let save = HQDownloadOutputStreamCallback("/Users/huangcong/Desktop/sss/fadfasf", isDirectory: false)
        HQDownloadScheduler.scheduler.download(url: URL(string: "http://static.smartisanos.cn/common/video/m1-white.mp4")!, options: [], callbacks: [save as HQDownloadCallback])
    }

}

