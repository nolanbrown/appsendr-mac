//
//  ASObject.h
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Foundation/Foundation.h>

@interface ASObject : NSObject<NSCoding>

- (BOOL) writeToDisk: (NSString *) path;
- (BOOL) destroyAtPath: (NSString *) path;
+ (id) loadFromDisk: (NSString *) path;
@end
