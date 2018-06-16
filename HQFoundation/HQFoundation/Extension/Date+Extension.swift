//
//  Date+Extension.swift
//  HQFoundation
//
//  Created by Magee Huang on 5/23/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import Foundation

extension Date: Namespaceable{}
extension Namespace where T == Date {
    public var isToday: Bool { return Calendar.current.isDateInToday(instance) }
    
    public var isTomorrow: Bool { return Calendar.current.isDateInTomorrow(instance) }
    
    public var isAfterTomorrow: Bool {
        let components = instance.hq.components(to: Date())
        if (components.day == 1 && components.hour == 23) {
            return true
        } else if (components.day == 2 && components.hour == 0) {
            return true
        }
        return false
    }
    
    public var isYesterday: Bool { return Calendar.current.isDateInYesterday(instance) }
    
    public var isBeforeYesterday: Bool {
        let components = instance.hq.components(to: Date())
        if (components.day == -1 && components.hour == -23) {
            return true
        } else if (components.day == -2 && components.hour == 0) {
            return true
        }
        return false
    }
    
    public var isWeekend: Bool { return Calendar.current.isDateInWeekend(instance) }

    public var isThisWeek: Bool {
        guard instance.hq.isThisYear else { return false }
        let week = Calendar.current.component(.weekOfYear, from: instance)
        let currWeek = Calendar.current.component(.weekOfYear, from: Date())
        return week == currWeek
    }
    
    public var isLastWeek: Bool {
        let lastWeek = Date(timeInterval: -1 * 7 * 24 * 60 * 60, since: instance)
        return lastWeek.hq.isThisWeek
    }
    
    public var isNextWeek: Bool {
        let nextWeek = Date(timeInterval: 7 * 24 * 60 * 60, since: instance)
        return nextWeek.hq.isThisWeek
    }
    
    public var isThisMonth: Bool {
        guard instance.hq.isThisYear else { return false }
        let month = Calendar.current.component(.month, from: instance)
        let currentMonth = Calendar.current.component(.month, from: Date())
        return month == currentMonth
    }
    
    public var isThisYear: Bool {
        let year = Calendar.current.component(.year, from: instance)
        let currYear = Calendar.current.component(.year, from: Date())
        return year == currYear
    }
    
    public func components(to date: Date) -> DateComponents {
        let units: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .nanosecond]
        var components = Calendar.current.dateComponents(units, from: instance, to: date)
        components.calendar = Calendar.current
        
        // Round up/down sub-second values.  Examples:  1.9871 = 2,  1.2314 = 1.
        let secondsRemainder = (components.nanosecond ?? 0) * (1 * Int(pow(10.0, -9.0)))
        components.second = secondsRemainder + (components.second ?? 0)
        return components;
    }
}
