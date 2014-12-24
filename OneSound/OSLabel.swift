//
//  OSLabel.swift
//  OneSound
//
//  Created by adam on 12/23/14.
//  Copyright (c) 2014 Adam Schoonmaker. All rights reserved.
//

import UIKit

// Label that draws with a variable border and color. Would recommend attributed text
// Based on: http://stackoverflow.com/questions/1103148/how-do-i-make-uilabel-display-outlined-text
class OSLabel: UILabel {
    
    var outlineWidth: CGFloat = 1.5
    var outlineColor: UIColor = UIColor.blackColor()
    var kerning = 0.5
    
    override func drawTextInRect(rect: CGRect) {
        let shadowOffset = self.shadowOffset
        let textColor = self.textColor
        
        let context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, outlineWidth)
        CGContextSetLineJoin(context, kCGLineJoinRound)
        
        CGContextSetTextDrawingMode(context, kCGTextStroke)
        self.textColor = outlineColor
        super.drawTextInRect(rect)
        
        CGContextSetTextDrawingMode(context, kCGTextFillStroke)
        self.textColor = textColor
        CGContextSetLineWidth(context, 0);
        self.shadowOffset = CGSizeMake(0, 0)
        super.drawTextInRect(rect)
        
        self.shadowOffset = shadowOffset
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
}
