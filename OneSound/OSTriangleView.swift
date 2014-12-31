//
//  OSTriangleView.swift
//  OneSound
//
//  Created by adam on 12/31/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

class OSTriangleView: UIView {

    var color: UIColor = UIColor.clearColor()
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));  // top left
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // top right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom right
        CGContextClosePath(ctx);
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        CGContextSetRGBFillColor(ctx, red, green, blue, alpha);
        CGContextFillPath(ctx);
    }

}
