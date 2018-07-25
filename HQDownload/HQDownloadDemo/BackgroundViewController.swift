////
////  BackgroundViewController.swift
////  HQDownloadDemo
////
////  Created by HonQi on 5/2/18.
////  Copyright © 2018 HonQi Indie. All rights reserved.
////
//
//import UIKit
//import HQDownload
//
//class BackgroundViewController: UIViewController {
//    var progressLabel = UILabel()
//    var imageView = UIImageView()
//    
//    let image = URL(string: "https://cdn.pixabay.com/photo/2018/01/31/12/16/architecture-3121009_1280.jpg")!
//    let directory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = UIColor.white
//        title = "单个文件下载"
//        
//        imageView.contentMode = .scaleAspectFit
//        imageView.frame = view.bounds
//        
//        progressLabel.text = "下载中......"
//        progressLabel.backgroundColor = UIColor.darkGray
//        progressLabel.textColor = UIColor.white
//        progressLabel.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: 44)
//        progressLabel.textAlignment = .center
//        
//        view.addSubview(progressLabel)
//        view.addSubview(imageView)
//        
//    }
//}
