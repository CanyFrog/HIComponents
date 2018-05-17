//
//  ScreenShot.swift
//  HQKit
//
//  Created by Magee on 2018/5/16.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

public struct ScreenShot {
    /// Call action when a screen shot is taken
    ///
    /// - Parameter action: executes after screen shot
    public func detect(_ action: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: .UIApplicationUserDidTakeScreenshot, object: nil, queue: OperationQueue.main) { (_) in
            action()
        }
    }
    
    public func shot() -> UIImage? {
        return UIApplication.shared.keyWindow?.hq.snapshot()
    }
}
