//
//  NSImage+AppSendr.h
//  AppSendr
//
//  Created by Nolan Brown on 4/12/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Cocoa/Cocoa.h>

@interface NSImage (AppSendr)
+ (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)newSize proportionally:(BOOL)prop;
@end
