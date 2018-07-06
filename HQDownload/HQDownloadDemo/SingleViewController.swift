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
    var op: Operator?
    
    let image = URL(string: "https://cdn.pixabay.com/photo/2018/01/31/12/16/architecture-3121009_1280.jpg")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "单个文件下载"
        
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        
        progressLabel.text = "初始化"
        progressLabel.backgroundColor = UIColor.darkGray
        progressLabel.textColor = UIColor.white
        progressLabel.font = UIFont.systemFont(ofSize: 10)
        progressLabel.frame = CGRect(x: 0, y: 104, width: view.frame.width, height: 44)
        progressLabel.textAlignment = .center
        
        view.addSubview(progressLabel)
        view.addSubview(imageView)
        
        op = Operator([.sourceUrl(image), .allowInvalidSSLCert])
        op?.subscribe(
            .start({ (_, name, size) in
                self.progressLabel.text = "Start download: name \(name) size \(size/1024) kb"
            }),
            .progress({ (_, rate) in
                self.progressLabel.text = "Downloading and progress is \(rate.completedUnitCount)/\(rate.totalUnitCount)"
            }),
            .completed({ (_, file) in
                self.progressLabel.text = "Completed"
                self.imageView.image = UIImage(contentsOfFile: file.path)
            }),
            .error({ (_, err) in
                self.progressLabel.text = err.description
            })
        )
        op?.start()
    }
}
