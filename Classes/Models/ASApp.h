//
//  ASApp.h
//  AppSendr
//
//  Created by Nolan Brown on 4/11/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ASObject.h"
#import "Icon.h"

@interface ASApp : ASObject <NSCoding> 
@property (nonatomic, copy) NSString *guid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSArray *schemes;

@property (nonatomic, strong) Icon *icon;

@property (nonatomic, copy) NSString *cachePath;

@property (nonatomic, copy) NSString *sourceFilename;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *sourceExtension;

@property (nonatomic, strong) NSURL *otaURL;
@property (nonatomic, copy) NSString *otaId;
@property (nonatomic, copy) NSString *deleteToken;

@property (nonatomic, strong) NSDate *addedAt;


- (id) initWithSourcePath: (NSString *) sourcePath;
+ (id) appWithSourcePath: (NSString *) appPath proccessingFinished:(void (^)(ASApp *app,BOOL success)) callback;
+ (id) appWithGUID: (NSString *) guid;

- (BOOL) save;
- (BOOL) destroy;
- (NSDictionary *) postParameters;
- (void) copyURLToClipboard;
- (NSString *) formattedAddedAt;

@end
