//
//  ObjCUtilities.h
//  OneSound
//
//  Created by adam on 3/6/15.
//  Copyright (c) 2015 Adam Schoonmaker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCUtilities : NSObject

// Use this instead of NSClassFromString to check if a class is available, there's a Swift bug this avoids
+ (BOOL) checkIfClassExists:(NSString *)className;

@end
