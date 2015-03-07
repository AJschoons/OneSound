//
//  ObjCUtilities.m
//  OneSound
//
//  Created by adam on 3/6/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

#import "ObjCUtilities.h"

@implementation ObjCUtilities

+ (BOOL) checkIfClassExists:(NSString *)className {
    id c = objc_getClass([className cStringUsingEncoding:NSASCIIStringEncoding]);
    if (c != nil) {
        return YES;
    } else {
        return NO;
    }
}

@end
