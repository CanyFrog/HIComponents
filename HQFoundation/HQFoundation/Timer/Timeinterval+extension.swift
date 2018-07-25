//
//  TimeInterval+extension.swift
//  HQFoundation
//
//  Created by HonQi on 5/14/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import Foundation


extension Namespace where T == TimeInterval {
    // MARK: - Time extensions
    public var millisecond: TimeInterval  { return instance / 1000 }
    public var milliseconds: TimeInterval { return instance / 1000 }
    public var ms: TimeInterval           { return instance / 1000 }
    
    public var second: TimeInterval       { return instance }
    public var seconds: TimeInterval      { return instance }
    
    public var minute: TimeInterval       { return instance * 60 }
    public var minutes: TimeInterval      { return instance * 60 }
    
    public var hour: TimeInterval         { return instance * 3600 }
    public var hours: TimeInterval        { return instance * 3600 }
    
    public var day: TimeInterval          { return instance * 3600 * 24 }
    public var days: TimeInterval         { return instance * 3600 * 24 }
}
