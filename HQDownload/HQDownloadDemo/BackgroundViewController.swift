//
//  BackgroundViewController.swift
//  HQDownloadDemo
//
//  Created by Magee Huang on 5/2/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit
import HQDownload

class BackgroundViewController: UIViewController {
    var progressLabel = UILabel()
    var imageView = UIImageView()
    
    let image = URL(string: "https://cdn.pixabay.com/photo/2018/01/31/12/16/architecture-3121009_1280.jpg")!
    let directory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "单个文件下载"
        
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        
        progressLabel.text = "下载中......"
        progressLabel.backgroundColor = UIColor.darkGray
        progressLabel.textColor = UIColor.white
        progressLabel.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: 44)
        progressLabel.textAlignment = .center
        
        view.addSubview(progressLabel)
        view.addSubview(imageView)
        
        var config = HQDownloadConfig()
        config.taskInBackground = true
        config.fetchFileInfo = true
        
        HQDownloader(source: image, config: config)
            .started { (fiel, total) in
                print("total \(total)")
            }
            .progress { (rece, frac) in
                print("received \(rece)")
                DispatchQueue.main.async {
                    self.progressLabel.text = "下载了\(rece/1024)kb, \(frac*100)%"
                }
            }
            .finished { (file, err) in
                print("finished.....")
                print("file \(String(describing: file?.path))")
                if let f = file {
                    DispatchQueue.main.async {
                        print("render image \(f)")
                        self.imageView.image = UIImage(contentsOfFile: f.path)
                    }
                }
            }.start()
    }
}
