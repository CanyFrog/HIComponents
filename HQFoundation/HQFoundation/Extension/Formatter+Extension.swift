//
//  Formatter+Extension.swift
//  HQFoundation
//
//  Created by HonQi on 5/23/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import Foundation


// MARK: - DateFormatter
extension Namespace where T: DateFormatter {
    // MARK: - only date
    
    /// e.g. "01/19/17"
    public func shortDateString(date: Date) -> String {
        instance.dateStyle = .short
        instance.timeStyle = .none
        return instance.string(from:date)
    }
    
    /// e.g. "Jan 19, 2017"
    public func mediumDateString(date: Date) -> String {
        instance.dateStyle = .medium
        instance.timeStyle = .none
        return instance.string(from:date)
    }
    
    /// e.g. "January 19, 2017"
    public func longDateString(date: Date) -> String {
        instance.dateStyle = .long
        instance.timeStyle = .none
        return instance.string(from:date)
    }
    
    /// e.g. "Thursday, January 19, 2017"
    public func fullDateString(date: Date) -> String {
        instance.dateStyle = .full
        instance.timeStyle = .none
        return instance.string(from:date)
    }
    
    
    // MARK: - only time
    
    /// e.g. "5:30 PM"
    public func shortTimeString(date: Date) -> String {
        instance.dateStyle = .none
        instance.timeStyle = .short
        return instance.string(from:date)
    }
    
    /// e.g. "5:30:45 PM"
    public func mediumTimeString(date: Date) -> String {
        instance.dateStyle = .none
        instance.timeStyle = .medium
        return instance.string(from:date)
    }
    
    /// e.g. "5:30:45 PM PST"
    public func longTimeString(date: Date) -> String {
        instance.dateStyle = .none
        instance.timeStyle = .long
        return instance.string(from:date)
    }
    
    /// e.g. "5:30:45 PM PST"
    public func fullTimeString(date: Date) -> String {
        instance.dateStyle = .none
        instance.timeStyle = .full
        return instance.string(from:date)
    }
}
