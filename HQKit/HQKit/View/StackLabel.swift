//
//  StackLabel.swift
//  HQKit
//
//  Created by HonQi on 6/8/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit

open class StackLabel: UIStackView {
    open var font: UIFont? {
        willSet { labels?.forEach{ $0.font = newValue } }
    }
    open var textColor: UIColor? {
        willSet { labels?.forEach{ $0.textColor = newValue } }
    }
    open var highlightColor: UIColor? {
        willSet { labels?.forEach{ $0.highlightedTextColor = newValue } }
    }
    open var disableColor: UIColor?
    
    open var isHighlight: Bool = false {
        willSet { labels?.forEach{ $0.setValue(newValue, forKey: "highlighted") } }
    }
    open var isEnable: Bool = false {
        willSet {
            if let disable = disableColor {
                labels?.forEach{ $0.textColor = newValue ? textColor : disable }
            }
            else {
                labels?.forEach{ $0.setValue(newValue, forKey: "enabled") }
            }
        }
    }
    
    private var labels: [UILabel]?
    
    
    public convenience init(labels: [UILabel]) {
        self.init(frame: .zero)
        self.labels = labels
        
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 5.0
        alignment = .center
        distribution = .fill
        
        labels.forEach{
            $0.translatesAutoresizingMaskIntoConstraints = false
            self.addArrangedSubview($0)
        }
    }
    
    public convenience init(texts: [String]) {
        let labels = texts.compactMap{ (text) -> UILabel in
            let label = UILabel.hq.autoLayout()
            label.text = text
            return label
        }
        self.init(labels: labels)
    }
}
