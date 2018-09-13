//
//  CAAnimation+HonQi.swift
//  HQKit
//
//  Created by Magee Huang on 9/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

extension Namespace where T: CAPropertyAnimation {
    public func `init`(key: AnimationKey) -> T {
        return T(keyPath: key.keyPath)
    }
}
