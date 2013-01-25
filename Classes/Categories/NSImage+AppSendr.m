//
//  NSImage+AppSendr.m
//  AppSendr
//
//  Created by Nolan Brown on 4/12/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "NSImage+AppSendr.h"

@implementation NSImage (AppSendr)

+ (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)newSize proportionally:(BOOL)prop
{
    if (image) {
        NSImage *copy = [image copy];
        NSSize size = [copy size];
        
        if (prop) {
            float rx, ry, r;
            
            rx = newSize.width / size.width;
            ry = newSize.height / size.height;
            r = rx < ry ? rx : ry;
            size.width *= r;
            size.height *= r;
        } else
            size = newSize;
        
        [copy setScalesWhenResized:YES];
        [copy setSize:size];
        
        return copy;
    }
    return nil; // or 'image' if you prefer.
}

@end
