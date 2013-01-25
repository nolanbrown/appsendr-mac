//
//  AndroidApp.h
//  AppSendr
//
//  decompressXML is based on work by Robo -
//  http://stackoverflow.com/questions/2097813/how-to-parse-the-androidmanifest-xml-file-inside-an-apk-package
//
//  Created by Nolan Brown on 4/11/12.

#import "ASApp.h"

struct decompressXML;

@interface AndroidApp : ASApp <NSCoding> {
@private
    struct decompressXML* impl;
}

@property (nonatomic, strong) NSDictionary *manifest;
@property (nonatomic, copy) NSString *apkPath;
@property (nonatomic, copy) NSString *appPath;
@property (nonatomic, strong) NSArray *activities;
@property (nonatomic, strong) NSArray *permissions;

- (id) initWithSourcePath: (NSString *) sourcePath proccessingFinished:(void (^)(ASApp *app,BOOL success)) callback;

@end
