//
//  ImageAsset.h
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "Asset.h"

@interface ImageAsset : Asset <NSCoding> {
    NSString *path_;
    NSImage *image_;
}
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSImage *image;

+ (id) imageAssetWithPath: (NSString *) path conversionComplete:(void (^)(NSString *filePath))block;
- (id) initWithPath: (NSString *) path conversionComplete:(void (^)(NSString *filePath))block;
@end
