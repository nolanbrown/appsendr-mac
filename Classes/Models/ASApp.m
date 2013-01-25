//
//  ASApp.m
//  AppSendr
//
//  Created by Nolan Brown on 4/11/12.
//  Copyright (c) 2013 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ASApp.h"
#import "iOSApp.h"
#import "AndroidApp.h"
#import "NSFileManager+DirectoryLocations.h"
#import "ASAPIClient.h"
typedef enum AppSourceType {
    ASApplication = 1,
    ASIpa = 2,
    ASApk = 3,

} AppSourceType;

static AppSourceType _sourceTypeFromPath(NSString *path) {
    NSString *pathExtension = [path pathExtension];
	if(pathExtension && ![pathExtension isEqualToString:@""]) {
		if([pathExtension isEqualToString:@"ipa"]) {
			return ASIpa;
		}
		else if([pathExtension isEqualToString:@"app"]) {
			return ASApplication;
		}
        else if([pathExtension isEqualToString:@"apk"]) {
			return ASApk;
		}
	}	
	return 0;
}

@implementation ASApp
@synthesize name = name_, version = version_, icon = icon_, sourcePath = sourcePath_, sourceExtension = sourceExtension_, cachePath = cachePath_, sourceFilename = sourceFilename_, identifier = identifier_, schemes = schemes_, guid= guid_, otaId = otaId_, otaURL = otaURL_, addedAt = addedAt_, deleteToken = deleteToken_;

+ (id) appWithGUID: (NSString *) guid {    
    NSString *caches = [[NSFileManager defaultManager] cachesDirectory];
    NSString *dir = [caches stringByAppendingPathComponent:guid];
    NSString *appFile = [dir stringByAppendingPathComponent:kASFileName];
    ASApp *app = [ASApp loadFromDisk:appFile];
    return app;
}

+ (id) appWithSourcePath: (NSString *) appPath proccessingFinished:(void (^)(ASApp *app, BOOL success)) callback {
    AppSourceType source = _sourceTypeFromPath(appPath);
    switch (source) {
        case ASApplication:
            return [[iOSApp alloc] initWithSourcePath:appPath proccessingFinished:callback];
            break;
        case ASIpa:
            return [[iOSApp alloc] initWithSourcePath:appPath proccessingFinished:callback];
            break;
            
        case ASApk:
            return [[AndroidApp alloc] initWithSourcePath:appPath proccessingFinished:callback];
            break;
            
        default:
            return nil;
            break;
    }
    return nil;
}

- (id) initWithSourcePath: (NSString *) sourcePath {
    self = [super init];
    if (self) {
        
        self.sourcePath = sourcePath;
        self.sourceFilename = [sourcePath lastPathComponent];
        self.sourceExtension = [sourcePath pathExtension];
        
        CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
        NSString	*uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
        CFRelease(uuidObj);
        self.guid = uuidString;
        
        self.cachePath = [[[NSFileManager defaultManager] cachesDirectory] stringByAppendingPathComponent:self.guid];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:@{} error:nil];
        
        ASLog(@"Source Path %@", self.sourcePath);
        ASLog(@"Source Extension %@", self.sourceExtension);
        ASLog(@"Source Filename %@", self.sourceFilename);
        ASLog(@"Cache Path %@", self.cachePath);

    }
    return self;

    
}

- (BOOL) save {
    NSString *path = [self.cachePath stringByAppendingPathComponent:kASFileName];
    BOOL written = [self writeToDisk:path];
    if(written) {
        ASLog(@"Written!");
        
    }
    else {
        ASLog(@"Failed to write to disk");
    }
    return written;
}

- (BOOL) destroy {
    NSString *path = [self.cachePath stringByAppendingPathComponent:kASFileName];
    return [self destroyAtPath:path];

}


- (void)dealloc
{
    guid_ = nil;
    otaId_ = nil;
    otaURL_ = nil;
    addedAt_ = nil;
    deleteToken_ = nil;
    
    sourceFilename_ = nil;
    cachePath_ = nil;
    version_ = nil;
    name_ = nil;
    sourcePath_ = nil;
    sourceExtension_ = nil;
    icon_ = nil;
    
}


//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.version forKey:@"version"];
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.schemes forKey:@"schemes"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeObject:self.cachePath forKey:@"cachePath"];
    [encoder encodeObject:self.sourceFilename forKey:@"sourceFilename"];
    [encoder encodeObject:self.sourcePath forKey:@"sourcePath"];
    [encoder encodeObject:self.sourceExtension forKey:@"sourceExtension"];
    [encoder encodeObject:self.guid forKey:@"guid"];
    [encoder encodeObject:self.otaURL forKey:@"otaURL"];
    [encoder encodeObject:self.otaId forKey:@"otaId"];
    [encoder encodeObject:self.addedAt forKey:@"addedAt"];
    [encoder encodeObject:self.deleteToken forKey:@"deleteToken"];
    
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.guid = [decoder decodeObjectForKey:@"guid"];
        self.otaURL = [decoder decodeObjectForKey:@"otaURL"];
        self.otaId = [decoder decodeObjectForKey:@"otaId"];
        self.addedAt = [decoder decodeObjectForKey:@"addedAt"];
        self.deleteToken = [decoder decodeObjectForKey:@"deleteToken"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.version = [decoder decodeObjectForKey:@"version"];
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.schemes = [decoder decodeObjectForKey:@"schemes"];
        self.icon = [decoder decodeObjectForKey:@"icon"];
        self.cachePath = [decoder decodeObjectForKey:@"cachePath"];
        self.sourceFilename = [decoder decodeObjectForKey:@"sourceFilename"];
        self.sourcePath = [decoder decodeObjectForKey:@"sourcePath"];
        self.sourceExtension = [decoder decodeObjectForKey:@"sourceExtension"];
    }
    return self;
}


- (NSDictionary *) postParameters { return nil; }

- (void) copyURLToClipboard {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSMutableArray *types = [NSMutableArray arrayWithObjects: NSStringPboardType, NSURLPboardType, nil];
    [pb declareTypes:types owner:self];
    [pb setString:[self.otaURL absoluteString] forType:NSStringPboardType];
    [pb setString:[self.otaURL absoluteString] forType:NSURLPboardType];
}

- (NSString *) formattedAddedAt {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, yyyy 'at' h:mm a"];
    return [dateFormatter stringFromDate:self.addedAt];
}

@end
