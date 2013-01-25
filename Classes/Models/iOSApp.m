//
//  AppManager.m
//  AppSendr
//
//  Created by Nolan Brown on 5/6/11.
//  Copyright 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "iOSApp.h"
#import "NSFileManager+DirectoryLocations.h"
#import <CommonCrypto/CommonDigest.h>
#import "Icon.h"
#import "ImageAsset.h"
#import "SSZipArchive.h"
    
static NSString *_parseFileUsingStringsCommand(NSString *filePath ) {
    NSTask *task;
    task = [[NSTask alloc] init];
	[task setLaunchPath: @"/bin/sh"];
	[task setStandardInput:[NSPipe pipe]];
    
	NSString *escapedpath = [filePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];	
	NSString *applicationSupportPath = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSString *outputPath = [applicationSupportPath stringByAppendingPathComponent:@"output.txt"];
    
	NSString *output = [outputPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
	NSArray *arguments;
    
	NSString *cmd = [NSString stringWithFormat:@"cat %@ | strings | od -t c -A n > %@",escapedpath, output];
    
    
	arguments = @[@"-c",cmd];
    
    [task setArguments: arguments];
    
    [task launch];
	[task waitUntilExit];
    
	NSData *data = [NSData dataWithContentsOfFile:outputPath];
    
    
	NSString *strippedString;
    strippedString = [[NSString alloc]
					  initWithData: data
					  encoding: NSASCIIStringEncoding];
	NSString *l = [strippedString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	l = [l stringByReplacingOccurrencesOfString:@"           " withString:@""];
	l = [l stringByReplacingOccurrencesOfString:@"   " withString:@""];
    
    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    return l;
}


@interface iOSApp (Private)
- (NSDictionary *) _readBundleInfo ;
- (void) _readProvisioningProfile:(void (^)(NSDictionary *profile))block;

@end


@implementation iOSApp

@synthesize ipaPath = ipaPath_;
@synthesize appPath = appPath_;
@synthesize provisioningProfile = provisioningProfile_;
@synthesize bundleInfo = bundleInfo_;
@synthesize assets = assets_;
@synthesize provisionedDevices = provisionedDevices_;


- (id) initWithSourcePath: (NSString *) sourcePath proccessingFinished:(void (^)(ASApp *app,BOOL success)) callback {
    self = [super initWithSourcePath:sourcePath];
    if (self) {
        
        // going to be an App or IPA
        
        if([self.sourceExtension isEqualToString:@"ipa"]) {// if IPA, open and make App

            self.ipaPath = [self.cachePath stringByAppendingPathComponent:self.sourceFilename];
            NSError *error = nil;
            
            [[NSFileManager defaultManager] copyItemAtPath:self.sourcePath toPath:self.ipaPath error:&error];
            
            NSString *appDirectory = [self.cachePath stringByAppendingPathComponent:[self.sourceFilename stringByDeletingPathExtension]];
            
            if([SSZipArchive unzipFileAtPath:self.ipaPath toDestination:appDirectory]) {
                NSString *payloadPath = [appDirectory stringByAppendingPathComponent:@"Payload"];
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payloadPath error:nil];
                if([files count] == 1) {
                    self.appPath = [payloadPath stringByAppendingPathComponent:files[0]];
                }
            }
            
        }
        else if([self.sourceExtension isEqualToString:@"app"]) {        // if App, make IPA

            NSError *error = nil;
            self.appPath = [self.cachePath stringByAppendingPathComponent:self.sourceFilename];

            [[NSFileManager defaultManager] copyItemAtPath:self.sourcePath toPath:self.appPath error:&error];
            ASLog(@"error %@",error);


            NSString *ipaParentDirectory = [self.cachePath stringByAppendingPathComponent:[self.sourceFilename stringByDeletingPathExtension]];
            
            NSString *ipaPayloadPath = [ipaParentDirectory stringByAppendingPathComponent:@"Payload"];
            NSString *ipaPayloadAppPath = [ipaPayloadPath stringByAppendingPathComponent:self.sourceFilename];
            ASLog(@"ipaPayloadAppPath %@",ipaPayloadAppPath);
            [[NSFileManager defaultManager] createDirectoryAtPath:ipaPayloadPath 
                                      withIntermediateDirectories:YES 
                                                       attributes:@{} 
                                                            error:&error];

            [[NSFileManager defaultManager] copyItemAtPath:self.appPath toPath:ipaPayloadAppPath error:&error];
            ASLog(@"ipaPayloadAppPath error %@",error);
            
            NSString *ipaName = [[self.sourceFilename stringByDeletingPathExtension] stringByAppendingPathExtension:@"ipa"];
            NSString *ipaPath = [self.cachePath stringByAppendingPathComponent:ipaName];

            //build IPA
            [self buildIPAFromAppAtPath:ipaPayloadPath writeToPath:ipaPath finished:^(NSString *finalIPAPath) {
                self.ipaPath = finalIPAPath;
                if(self.icon) {
                    callback(self,YES);
                }
            }];
            
        }


        // read Info.plist

        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.appPath];
        
        for (NSString *filename in fileEnumerator) {
            if([filename isEqualToString:@"Info.plist"]) {
                self.bundleInfo = [NSDictionary dictionaryWithContentsOfFile:[self.appPath stringByAppendingPathComponent:filename]];
                break;
            }
        }
        
        if(self.bundleInfo) {
            self.version = (self.bundleInfo)[@"CFBundleVersion"];
            
            self.name = (self.bundleInfo)[@"CFBundleDisplayName"];
            
            NSString *formattedAppName = [[self.name stringByReplacingOccurrencesOfString:@" " 
                                                                                 withString:@"_"] 
                                          stringByReplacingOccurrencesOfString:@"*" 
                                          withString:@""];
            
            self.identifier = [(self.bundleInfo)[@"CFBundleIdentifier"] stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME:rfc1034identifier}"
                                                                                                                    withString:formattedAppName];
            NSMutableArray *schemes = [NSMutableArray array];
            NSArray *urls = (self.bundleInfo)[@"CFBundleURLTypes"];
            for(NSDictionary *url in urls) {
                NSArray *schemeURLs = url[@"CFBundleURLSchemes"];
                NSString *scheme = schemeURLs[0];
                if(scheme) {
                    [schemes addObject:scheme];
                }
            }
            self.schemes = schemes;
        }


        [self _readProvisioningProfile:^(NSDictionary *profile) {
            self.provisioningProfile = profile;
            [self save];
        }];
        
    
        self.icon = [[Icon alloc] initWithApp:self imageProcessingFinished:^(Icon *icon){
            self.icon = icon;
            if(self.ipaPath) {
                callback(self,YES);
            }
        }];            

        
    }
    return self;
    
    
}


- (void)dealloc
{

    files_ = nil;


    name_ = nil;
    originalPath_ = nil;
    workingPath_ = nil;
    provisioningProfile_ = nil;
    bundleInfo_ = nil;
    assets_ = nil;

}


//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.ipaPath forKey:@"ipaPath"];
    [encoder encodeObject:self.appPath forKey:@"appPath"];
    [encoder encodeObject:self.bundleInfo forKey:@"bundleInfo"];
    [encoder encodeObject:self.provisioningProfile forKey:@"provisioningProfile"];
    [encoder encodeObject:self.provisionedDevices forKey:@"provisionedDevices"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super initWithCoder:decoder])) {
        self.ipaPath = [decoder decodeObjectForKey:@"ipaPath"];
        self.appPath = [decoder decodeObjectForKey:@"appPath"];
        self.bundleInfo = [decoder decodeObjectForKey:@"bundleInfo"];
        self.provisioningProfile = [decoder decodeObjectForKey:@"provisioningProfile"];
        self.provisionedDevices = [decoder decodeObjectForKey:@"provisionedDevices"];
    }
    return self;
}




- (void) _readProvisioningProfile:(void (^)(NSDictionary *profile))block  {
	
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *profilePath = nil;
        
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.appPath];
        
        for (NSString *filename in fileEnumerator) {
            if([[filename lastPathComponent] rangeOfString:@"embedded.mobileprovision"].location != NSNotFound) {
                profilePath = [self.appPath stringByAppendingPathComponent:filename];
                
                break;
            }
        }	
        if(profilePath) {
            NSString *emeddedMobileProvisioning = _parseFileUsingStringsCommand(profilePath);		
            NSArray *lines = [emeddedMobileProvisioning componentsSeparatedByString:@"\\n"];
            
            NSMutableString *plist = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"];
            BOOL plistStart = NO;
            BOOL plistEnd = NO;
            for(__strong NSString *line in lines) {
                line  =
                [line stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if(plistStart == YES && plistEnd == NO) { //store everything in between
                    //ASLog(@"%@",line);
                    
                    [plist appendString:line];
                }
                else if([line isEqualToString:@"<plist version=\"1.0\">"] && plistStart == NO) {
                    plistStart = YES;
                    [plist appendString:line];
                    
                }
                else if([line isEqualToString:@"</plist>"] && plistEnd == NO) {
                    
                    plistEnd = YES;
                    [plist appendString:line];
                }
                
            }
            NSData* plistData = [plist dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSPropertyListFormat format;
            NSDictionary* plistDict = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(plistDict);
                
            }); 
            
        }
        else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                block(nil);
            });            
        }
        
        
        
    });
}

#pragma mark -

- (void) loadImageAssets:(void (^)(CGFloat progress, NSString *filename))progress  onCompletion: (void (^)(ASApp *app, NSArray *assets)) finished {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSMutableArray *images = [NSMutableArray array];
        CGFloat numFiles = (CGFloat)[files_ count];
        CGFloat i = 0.0;
        for(NSString *filePath in files_) {
            i+=1.0;
            ImageAsset *asset = [ImageAsset imageAssetWithPath:filePath conversionComplete:^(NSString *imgPath) {
                CGFloat prog = i/numFiles;
                progress(prog,[imgPath lastPathComponent]);
            }];
            if(asset) {
                [images addObject:asset];
            }
        }
        self.assets = images;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            finished(self, self.assets);
        });
    });
}



- (void) analyzeFiles: (void (^)(NSDictionary *anlysis)) callback {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSMutableDictionary *fileTypes = [NSMutableDictionary dictionary];
        
        
        for (NSString *filePath in files_) {
            NSString *type = [[filePath lastPathComponent] pathExtension];
            
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
                
                NSMutableDictionary *typeDictionary = [NSMutableDictionary dictionaryWithDictionary:fileTypes[type]];
                if(!typeDictionary) {
                    typeDictionary = [NSMutableDictionary dictionary];
                }
                NSNumber *num = typeDictionary[@"total_files"];
                
                if(num) {
                    num = @([num intValue] + 1);
                }
                else {
                    num = @1;
                }
                typeDictionary[@"total_files"] = num;
                
                
                
                float theSize  = 0;
                NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                theSize += [fattrs[NSFileSize] floatValue];
                
                NSNumber *typenum = typeDictionary[@"total_size"];
                if(typenum) {
                    typenum = [NSNumber numberWithInt:([typenum floatValue] + theSize)];
                }
                else {
                    typenum = @(theSize);
                }
                
                
                typeDictionary[@"total_size"] = typenum;
                
                fileTypes[type] = typeDictionary;
                
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(fileTypes);
        });
    });
    
    
    
    
}



#pragma mark - IPA

- (void) buildIPAFromAppAtPath: (NSString *) appPath writeToPath: (NSString *) ipaPath finished:(void (^)(NSString *finalPath))block  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath: @"/usr/bin/ditto"];
        [task setStandardInput:[NSPipe pipe]];
        
        NSArray *arguments = @[@"-c", @"-k", @"--keepParent", @"--sequesterRsrc",appPath, ipaPath];
        [task setArguments: arguments];
        
        [task launch];
        
        while([task isRunning]) {
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(ipaPath);
        }); 
    });
    
    
}
@end
