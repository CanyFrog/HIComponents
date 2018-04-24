//
//  SingleViewController.swift
//  HQDownloadDemo
//
//  Created by Magee Huang on 4/24/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit
import HQDownload

class SingleViewController: UIViewController {
    var progressLabel = UILabel()
    var imageView = UIImageView()
    
    let image = "https://cdn.pixabay.com/photo/2018/04/22/12/48/owl-3340957_1280.jpg"
    
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
        
        HQDownloader.Downloader.download(URL(string: image)!) { (file, oper) in
            if let f = file {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(contentsOfFile: f.path)
                    self.progressLabel.text = "缓存图片"
                }
            }
            else {
                oper?.progress({ (comp, frac) in
                    DispatchQueue.main.async {
                        self.progressLabel.text = "下载了\(comp/1024)kb, \(frac*100)%"
                        if let data = try? Data(contentsOf: oper!.progress.fileUrl!) {
                            self.imageView.image = UIImage(data: data)
                        }
                    }
                })
            }
        }
    }
}
