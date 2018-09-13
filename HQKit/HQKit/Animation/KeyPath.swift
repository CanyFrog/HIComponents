//
//  KeyPath.swift
//  HQKit
//
//  Created by HonQi Huang on 9/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

public protocol AnimationKey {
    var keyPath: String { get }
}

public enum ShapeLayerKey: AnimationKey {
    
    case fillColor
    case strokeColor
    case strokeStart
    case strokeEnd
    case lineWidth
    case miterLimit
    case lineDashPhase

    public var keyPath: String {
        switch self {
        case .fillColor:            return #keyPath(CAShapeLayer.fillColor)
        case .strokeColor:          return #keyPath(CAShapeLayer.strokeColor)
        case .strokeStart:          return #keyPath(CAShapeLayer.strokeStart)
        case .strokeEnd:            return #keyPath(CAShapeLayer.strokeEnd)
        case .lineWidth:            return #keyPath(CAShapeLayer.lineWidth)
        case .miterLimit:           return #keyPath(CAShapeLayer.miterLimit)
        case .lineDashPhase:        return #keyPath(CAShapeLayer.lineDashPhase)
        }
    }
}

public enum LayerKey: AnimationKey {
    case transform(Dimension)
    case position
    case positionZ
    case bounds
    case anchor
    case anchorZ
    case corner
    case backgroundColor
    case contents
    case contentsRect
    case maskToBounds
    case borderColor
    case borderWidth
    case shadowColor
    case shadowOffset
    case shadowOpacity
    case shadowRadius
    case shadowPath
    case opacity
    case hidden
    case mask
    case sublayers
    case sublayerTransform
    
    
    public var keyPath: String {
        switch self {
        case .transform(let dim):   return #keyPath(CALayer.transform) + dim.keyPath
        case .position:             return #keyPath(CALayer.position)
        case .positionZ:            return #keyPath(CALayer.zPosition)
        case .bounds:               return #keyPath(CALayer.bounds)
        case .anchor:               return #keyPath(CALayer.anchorPoint)
        case .anchorZ:              return #keyPath(CALayer.anchorPointZ)
        case .corner:               return #keyPath(CALayer.cornerRadius)
        case .backgroundColor:      return #keyPath(CALayer.backgroundColor)
        case .contents:             return #keyPath(CALayer.contents)
        case .contentsRect:         return #keyPath(CALayer.contentsRect)
        case .maskToBounds:         return #keyPath(CALayer.masksToBounds)
        case .borderColor:          return #keyPath(CALayer.borderColor)
        case .borderWidth:          return #keyPath(CALayer.borderWidth)
        case .shadowColor:          return #keyPath(CALayer.shadowColor)
        case .shadowOffset:         return #keyPath(CALayer.shadowOffset)
        case .shadowOpacity:        return #keyPath(CALayer.shadowOpacity)
        case .shadowRadius:         return #keyPath(CALayer.shadowRadius)
        case .shadowPath:           return #keyPath(CALayer.shadowPath)
        case .opacity:              return #keyPath(CALayer.opacity)
        case .hidden:               return #keyPath(CALayer.isHidden)
        case .mask:                 return #keyPath(CALayer.mask)
        case .sublayers:            return #keyPath(CALayer.sublayers)
        case .sublayerTransform:    return #keyPath(CALayer.sublayerTransform)
        }
    }
    
    
    public enum Dimension {
        case rotation(Axis)
        case scale(Axis)
        case translation(Axis)
        case all
        
        var keyPath: String {
            switch self {
            case .rotation(let ax): return ".rotation" + ax.keyPath
            case .scale(let ax): return ".scale" + ax.keyPath
            case .translation(let ax): return ".translation" + ax.keyPath
            case .all: return ""
            }
        }
        
        public enum Axis {
            case x
            case y
            case z
            case all
            
            var keyPath: String {
                switch self {
                case .x: return ".x"
                case .y: return ".y"
                case .z: return ".z"
                case .all: return ""
                }
            }
        }
    }
}
