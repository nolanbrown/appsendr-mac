//
//  Icon.h
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Foundation/Foundation.h>
#import "ImageAsset.h"
@class ASApp;

@interface Icon : ImageAsset {

}
@property (nonatomic, strong) ASApp *app;
@property (nonatomic, strong) NSString *processedIconPath;
@property (nonatomic, strong) NSImage *smallImage;
@property (nonatomic, strong) NSImage *largeImage;

- (id) initWithApp: (ASApp* ) app imageProcessingFinished:(void (^)(Icon *icon)) callback;

- (NSData *) imageData;
@end
