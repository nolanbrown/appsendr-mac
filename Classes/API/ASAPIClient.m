//
//  ASAPIClient.m
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ASAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "ASApp.h"
#import "iOSApp.h"
#import "AndroidApp.h"

@interface ASAPIClient (Private)
- (void) _splitFileAtPath: (NSString *) path intoDirectory: (NSString *) dir;
+(NSMutableDictionary *) _authenticatedParamters ;
@end

@implementation ASAPIClient

+ (ASAPIClient *)sharedClient {
    static ASAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kAppSendrBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];

    return self;
}

- (void) destroyApp: (ASApp*) app finished: (void (^)(BOOL successful))finished {
    NSString *path = [NSString stringWithFormat:@"/v1/app/%@",app.otaId];
    if(!app.deleteToken) {
        finished(NO);
        return;
    }
    
    
    [self deletePath:path
          parameters:@{ @"token" : app.deleteToken }
             success:^(AFHTTPRequestOperation *operation, id response){
                 finished(YES);
             }
             failure:^(AFHTTPRequestOperation *operation, id response){
                 finished(NO);
             }];
}


- (void) uploadApp: (ASApp*) app withProgressCallback: (void (^)(CGFloat progess))progress finished: (void (^)(BOOL successful, id response))finished {
    
    NSData *imageData = [app.icon imageData];
    
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if(app.identifier)
        dictionary[@"identifier"] = app.identifier;
    
    
    NSMutableURLRequest *request = [[[self class] sharedClient] multipartFormRequestWithMethod:@"POST" 
                                                                                          path:@"/v1/app/new" 
                                                                                    parameters:dictionary 
                                                                     constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
         if(imageData) {
             NSString *name = [[app.icon processedIconPath] lastPathComponent];
             [formData appendPartWithFileData:imageData name:@"icon" fileName:name mimeType:@"image/png"];   
         }
         if([app isKindOfClass:[iOSApp class]]) {
             iOSApp *iapp = (iOSApp *) app;
             NSData *ipa = [NSData dataWithContentsOfFile:iapp.ipaPath];
             [formData appendPartWithFileData:ipa name:@"app_data" fileName:[iapp.ipaPath lastPathComponent] mimeType:@"application/x-itunes-ipa"];
         } else if ([app isKindOfClass:[AndroidApp class]]) {
             AndroidApp *aapp = (AndroidApp *) app;
             NSData *apk = [NSData dataWithContentsOfFile:aapp.apkPath];
             [formData appendPartWithFileData:apk name:@"app_data" fileName:[aapp.apkPath lastPathComponent] mimeType:@"application/vnd.android.package-archive"];
         }
                                                                        
                                                                         
                                                                         
                                                                         

    }];
    
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        CGFloat tb = totalBytesExpectedToWrite;
        CGFloat tbw = totalBytesWritten;

        progress(tbw/tb);
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id response) {
        ASLog(@"response %@",response);
        finished(YES, response);
    }
                                     failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
                                         ASLog(@"error %@",[error localizedDescription]);
                                         finished(NO, nil);
    }];
    
    
    [operation start];
        
}



- (void) _splitFileAtPath: (NSString *) path intoDirectory: (NSString *) dir {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/split"];
    [task setCurrentDirectoryPath:dir];
	[task setStandardInput:[NSPipe pipe]];
    
    NSArray *arguments;
    arguments = @[@"-b", @"5mb", path];
    [task setArguments: arguments];
    
    [task launch];
    
    while([task isRunning]) {
        
    }
}


@end