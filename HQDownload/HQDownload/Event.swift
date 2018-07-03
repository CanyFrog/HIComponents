//
//  Event.swift
//  HQDownload
//
//  Created by Magee Huang on 7/3/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

public protocol Event {}
public enum OperatorEvent: Event {
    case start((String, Int64)) // start Name and size
    case progress(Progress)
    case newData(Data)
    case completed(URL) // completion file url
    case error(Swift.Error)
}

public enum SchedulerEvent: Event {
    case start((URL, String, Int64))
    case progress([Progress])
    case completed((URL, URL))
    case error((URL, Swift.Error))
}

public enum ManagerEvent: Event {}


public protocol Executable {
    associatedtype E = Event
    func execute(_ event: E)
}
