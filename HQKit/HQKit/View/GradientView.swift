//
//  GradientView.swift
//  HQKit
//
//  Created by Magee Huang on 6/7/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit


/// Use UIView to realize the function of CAGradientLayer, for more convenient use and AutoLayout
open class GradientView: UIView {
    private var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }
    
    open override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func gradientVertical(colors: [UIColor], locations: [NSNumber]? = nil) {
        gradient(colors: colors, locations: locations, startPoint: CGPoint(x: 0.5, y: 1), endPoint: CGPoint(x: 0.5, y: 0))
    }
    
    open func gradientHorizontal(colors: [UIColor], locations: [NSNumber]? = nil) {
        gradient(colors: colors, locations: locations, startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
    }
    
    open func gradient(colors: [UIColor], locations: [NSNumber]? = nil, startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        var locas = locations
        if locas == nil {
            locas = Array(repeating: 1.0 / Float(colors.count), count: colors.count) as [NSNumber]
        }
        
        let colorLayer = gradientLayer
        colorLayer.colors = colors.compactMap{ $0.cgColor }
        colorLayer.locations = locas
        colorLayer.startPoint = startPoint
        colorLayer.endPoint = endPoint
    }
}
