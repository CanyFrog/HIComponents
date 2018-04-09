////
////  HQDownloadCallback.swift
////  HQDownload
////
////  Created by qihuang on 2018/3/30.
////  Copyright © 2018年 com.personal.HQ. All rights reserved.
////
//
//public typealias HQDownloaderProgressClosure = ((_ data: Data?, _ receivedSize: Int, _ expectedSize: Int, _ targetUrl: URL)->Void)
//public typealias HQDownloaderCompletedClosure = ((_ error: Error?)->Void)
//
//public class HQDownloadCallback: Hashable {
//
//    private let createTimestamp: TimeInterval = Date().timeIntervalSince1970 * 1000 * 1000
//    public var url: URL?
//    public weak var operation: HQDownloadOperation?
//    public var progressClosure: HQDownloaderProgressClosure?
//    public var completedClosure: HQDownloaderCompletedClosure?
//
//    public init() { }
//
//    public convenience init(url: URL? = nil, operation: HQDownloadOperation? = nil, progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) {
//        self.init()
//        self.url = url
//        self.operation = operation
//        self.progressClosure = progress
//        self.completedClosure = completed
//    }
//
//    public func cancel() {
//        operation?.cancel(self)
//    }
//
//    public var hashValue: Int {
//        return Int(createTimestamp)
//    }
//
//    public static func ==(lhs: HQDownloadCallback, rhs: HQDownloadCallback) -> Bool {
//        return lhs.hashValue == rhs.hashValue
//    }
//}
//
//public class HQDownloadOutputStreamCallback: HQDownloadCallback {
//    private var stream: OutputStream?
//    private var saveDir: String!
//
//    private override init() {
//        super.init()
//        progressClosure = createProgressClosure()
//        completedClosure = createCompletedClosure()
//    }
//
//    public convenience init(directory: String = NSTemporaryDirectory()) {
//        self.init()
//        saveDir = directory.last! == "/" ? directory : directory.appending("/")
//    }
//
//    private func createProgressClosure() -> HQDownloaderProgressClosure {
//        return { [weak self] (data, recv, total, url) in
//            if let d = data {
//                self?.stream?.write([UInt8](d), maxLength: d.count)
//            }
//            else {
//                self?.openStream(url)
//            }
//        }
//    }
//
//    private func createCompletedClosure() -> HQDownloaderCompletedClosure {
//        return { [weak self] (err) in
//            self?.closeStream()
//        }
//    }
//
//    private func openStream(_ url: URL) {
//        if stream == nil { stream = OutputStream(toFileAtPath: "\(saveDir)\(url.lastPathComponent.utf8)", append: true) }
//        if stream?.streamStatus == .notOpen {
//            stream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
//            stream?.open()
//        }
//    }
//
//    private func closeStream() {
//        stream?.close()
//        stream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
//    }
//
//    deinit {
//        closeStream()
//        self.cancel()
//    }
//}
