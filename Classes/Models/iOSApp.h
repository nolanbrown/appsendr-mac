//
//  App.h
//  AppSendr
//
//  Created by Nolan Brown on 5/6/11.
//  Copyright 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import <Foundation/Foundation.h>
#import "ASApp.h"

@class Icon;

@interface iOSApp : ASApp <NSCoding> {

    NSDictionary *bundleInfo_;
    NSDictionary *provisioningProfile_;
    NSDictionary *dataProfile_;

    NSString *originalPath_;
    NSString *workingPath_;
    NSString *name_;
    NSArray *assets_;
    NSArray *provisionedDevices_;
    
@private

    NSArray *files_;
	NSFileHandle *fileHandle_;
    NSTask *task_;


}

@property (nonatomic, copy) NSString *ipaPath;
@property (nonatomic, copy) NSString *appPath;
@property (nonatomic, strong) NSDictionary *bundleInfo;

@property (nonatomic, strong) NSDictionary *provisioningProfile;
@property (nonatomic, strong) NSArray *provisionedDevices;

@property (nonatomic, strong) NSArray *assets;

- (id) initWithSourcePath: (NSString *) sourcePath proccessingFinished:(void (^)(ASApp *app, BOOL success)) callback;

@end
