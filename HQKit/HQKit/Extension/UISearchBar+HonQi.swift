//
//  UISearchBar+HonQi.swift
//  HQKit
//
//  Created by Magee Huang on 9/4/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

extension Namespace where T: UISearchBar {
    public var searchField: UITextField {
        return instance.value(forKeyPath: "searchField") as! UITextField
    }
}
