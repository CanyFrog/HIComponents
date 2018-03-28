//
//  ViewController.swift
//  HQDownloadDemo
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var session: URLSession!
    var fileLength: Int64?
    var currentLength: Int64 = 0
    var fileHandle: FileHandle?
    var downloadTask: URLSessionDataTask?
    var queue: OperationQueue = OperationQueue()
    
    var op1: myOperation = myOperation()
    var op2: myOperation = myOperation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let btn = UIButton(frame: CGRect.init(x: 0, y: 0, width: 100, height: 44))
        btn.setTitle("百度云MAC", for: .normal)
        btn.backgroundColor = UIColor.black
        view.addSubview(btn)
        btn.addTarget(self, action: #selector(clickBtn(btn:)), for: .touchUpInside)
        btn.center = view.center
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    
    @objc func clickBtn(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        
        op1.printStr = "test 1 operation"
        op2.printStr = "test 2 operation"
        op2.sleepTime = 3
        
        op1.completionBlock = { [unowned self] in
//            print("queue has \(self.queue.operationCount) operation")
            
            if self.op1.isFinished {
//                self.op1.printStr = "test 1 again"
//                self.queue.addOperation(self.op1)
                print("queue has \(self.queue.operationCount) operation")
                
            }
        }
        
        queue.addOperation(op1)
        queue.addOperation(op2)
    }

    func downloadTest(isSelected: Bool) {
        let toPath = "/Users/huangcong/Desktop/sss/tmp_baidu.dmg"
        createTask()
        if isSelected {
            let length = getFileLength(path: toPath)
            if length > 0 {
                currentLength = length
            }
            downloadTask?.resume()
        }
        else {
            downloadTask?.suspend()
            downloadTask = nil
        }
        //        var urlStr = "http://issuecdn.baidupcs.com/issue/netdisk/MACguanjia/BaiduNetdisk-mac-2.2.1.dmg"
        
        //            urlStr = "http://issuecdn.baidupcs.com/issue/netdisk/yunguanjia/BaiduNetdisk_6.0.2.exe"
        
        //        let urlStr = "http://storage.slide.news.sina.com.cn/slidenews/77_ori/2018_12/74766_816911_684715.gif"
    }
    
    func getFileLength(path: String) -> Int64 {
        let fileM = FileManager()
        if fileM.fileExists(atPath: path) {
            let dict = try? fileM.attributesOfFileSystem(forPath: path)
            if let d = dict {
                return d[FileAttributeKey.systemFreeSize] as! Int64
            }
        }
        return 0
    }
    func createTask() {
        let url = URL(string: "http://issuecdn.baidupcs.com/issue/netdisk/yunguanjia/BaiduNetdisk_6.0.2.exe")
        
        var request = URLRequest(url: url!)
        let range = String(format: "bytes=%zd-", currentLength)
        request.setValue(range, forHTTPHeaderField: "Range")
        downloadTask = session.dataTask(with: request)
    }

}

extension ViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        fileLength = response.expectedContentLength + currentLength
        print("file lenght is \(fileLength)")
        let toPath = "/Users/huangcong/Desktop/sss/tmp_baidu.dmg"
        let fileM = FileManager.default
        if !fileM.fileExists(atPath: toPath) {
            fileM.createFile(atPath: toPath, contents: nil, attributes: nil)
        }
        print("start download")
        fileHandle = FileHandle(forWritingAtPath: toPath)
        
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        fileHandle?.seekToEndOfFile()
        fileHandle?.write(data)
        
        currentLength += Int64(data.count)
        print(currentLength)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        fileHandle?.closeFile()
        fileHandle = nil
        currentLength = 0
        fileLength = 0
        print("download finish")
    }
}

class myOperation: Operation {
    var printStr: String?
    var sleepTime: UInt32 = 1
    
    override func main() {
        sleep(sleepTime)
        print(printStr!)
        completionBlock?()
    }
}
