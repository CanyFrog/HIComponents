//
//  DataProvider.swift
//  HQRouter
//
//  Created by Magee Huang on 5/17/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

public protocol DataProvider {
    func invoke<T>(name: String, params: [String: Any]) -> T?
}

extension DataProvider {
    func invoke<T>(name: String, params: [String: Any]) -> T? {
        return nil
    }
}
