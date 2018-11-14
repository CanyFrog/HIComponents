//
//  UIImage+HonQi.swift
//  HQKit
//
//  Created by HonQi on 2018/5/17.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation
import Accelerate

extension Namespace where T: UIImage {
    
    /// Create new image with color and size
    public static func image(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// Resize image to new size
    public func resize(size: CGSize) -> UIImage? {
        var w: CGFloat?
        var h: CGFloat?
        
        if 0 < size.width {
            h = instance.size.height * size.width / instance.size.width
        }
        else if 0 < size.height {
            w = instance.size.width * size.height / instance.size.height
        }
        
        let rect: CGRect = CGRect(x: 0, y: 0, width: w ?? size.width, height: h ?? size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        instance.draw(in: rect, blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// Render color to current image
    public func render(color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(instance.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        defer { UIGraphicsEndImageContext() }
        
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0.0, y: -instance.size.height)
        
        context?.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: instance.size.width, height: instance.size.height)
        context?.clip(to: rect, mask: instance.cgImage!)
        color.setFill()
        context?.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
    }
    
    /// Crops an image to a specified size
    public func crop(size: CGSize) -> UIImage? {
        let rate: CGFloat = min(size.height / instance.size.height, size.width / instance.size.width)
        let w = instance.size.width * rate
        let h = instance.size.height * rate
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let rect = instance.size.width > instance.size.height ? CGRect(x: -1 * (w - size.width) / 2, y: 0, width: w, height: h) : CGRect(x: 0, y: -1 * (h - size.height) / 2, width: w, height: h)
        
        instance.draw(in: rect, blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Applies a blur effect to a UIImage
    ///
    /// - Parameters:
    ///   - radius: The radius of the blur effect
    ///   - tintColor: The color used for the blur effect
    ///   - saturationDeltaFactor: The delta factor for the saturation of the blur effect
    public func blur(radius: CGFloat = 0, tintColor: UIColor? = nil, saturationDeltaFactor: CGFloat = 0) -> UIImage? {
        
        /// Creates an effect buffer for images that already have effects
        func createEffectBuffer(context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }
        
        
        var effectImage: UIImage = instance
        
        let screenScale = UIScreen.main.scale
        let imageRect = CGRect(origin: .zero, size: instance.size)
        let hasBlur = radius > CGFloat(Float.ulpOfOne)
        let hasSaturationChange = fabs(saturationDeltaFactor - 1.0) > CGFloat(Float.ulpOfOne)
        
        if hasBlur || hasSaturationChange {
            UIGraphicsBeginImageContextWithOptions(instance.size, false, screenScale)
            let inContext = UIGraphicsGetCurrentContext()!
            inContext.scaleBy(x: 1.0, y: -1.0)
            inContext.translateBy(x: 0, y: -instance.size.height)
            
            inContext.draw(instance.cgImage!, in: imageRect)
            
            var inBuffer = createEffectBuffer(context: inContext)
            
            UIGraphicsBeginImageContextWithOptions(instance.size, false, screenScale)
            
            let outContext = UIGraphicsGetCurrentContext()!
            var outBuffer = createEffectBuffer(context: outContext)
            
            if hasBlur {
                let a = sqrt(2 * .pi)
                let b = CGFloat(a) / 4
                let c = radius * screenScale
                let d = c * 3.0 * b
                
                var e = UInt32(floor(d + 0.5))
                
                if 1 != e % 2 {
                    e += 1 // force radius to be odd so that the three box-blur methodology works.
                }
                
                let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
                
                vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, e, e, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&outBuffer, &inBuffer, nil, 0, 0, e, e, nil, imageEdgeExtendFlags)
                vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, e, e, nil, imageEdgeExtendFlags)
            }
            
            var effectImageBuffersAreSwapped = false
            
            if hasSaturationChange {
                let s = saturationDeltaFactor
                
                let floatingPointSaturationMatrix: [CGFloat] = [
                    0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                    0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                    0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                    0,                    0,                    0,                    1
                ]
                
                let divisor: CGFloat = 256
                let matrixSize = floatingPointSaturationMatrix.count
                var saturationMatrix = [Int16](repeating: 0, count: matrixSize)
                
                for i in 0..<matrixSize {
                    saturationMatrix[i] = Int16(round(floatingPointSaturationMatrix[i] * divisor))
                }
                
                if hasBlur {
                    vImageMatrixMultiply_ARGB8888(&outBuffer, &inBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                } else {
                    vImageMatrixMultiply_ARGB8888(&inBuffer, &outBuffer, saturationMatrix, Int32(divisor), nil, nil, vImage_Flags(kvImageNoFlags))
                }
            }
            
            if !effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()!
            }
            
            UIGraphicsEndImageContext()
            
            if effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext()!
            }
            
            UIGraphicsEndImageContext()
        }
        
        // Set up output context.
        UIGraphicsBeginImageContextWithOptions(instance.size, false, screenScale)
        let outputContext = UIGraphicsGetCurrentContext()!
        outputContext.scaleBy(x: 1.0, y: -1.0)
        outputContext.translateBy(x: 0, y: -instance.size.height)
        
        // Draw base image.
        outputContext.draw(instance.cgImage!, in: imageRect)
        
        // Draw effect image.
        if hasBlur {
            outputContext.saveGState()
            outputContext.draw(effectImage.cgImage!, in: imageRect)
            outputContext.restoreGState()
        }
        
        // Add in color tint.
        if let v = tintColor {
            outputContext.saveGState()
            outputContext.setFillColor(v.cgColor)
            outputContext.fill(imageRect)
            outputContext.restoreGState()
        }
        
        // Output image is ready.
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return outputImage
    }
}
