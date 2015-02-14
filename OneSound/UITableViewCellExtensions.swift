//
//  UITableViewCellExtensions.swift
//  OneSound
//
//  Created by adam on 2/14/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

extension UITableViewCell {
    // Makes the cells have no layout margin in iOS 8 (to behave same as iOS 7)
    // Must be done for all custom cells
    // Property doesn't exist in iOS 7, so won't be accessed then
    override public var layoutMargins: UIEdgeInsets {
        get { return UIEdgeInsetsZero }
        set { }
    }
}