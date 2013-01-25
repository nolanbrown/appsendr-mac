//
//  ImageAsset.m
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012 AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ImageAsset.h"
#import <Quartz/Quartz.h>
#import "NSFileManager+DirectoryLocations.h"


@implementation ImageAsset

@synthesize path = path_;
@synthesize image = image_;

+ (id) imageAssetWithPath: (NSString *) path conversionComplete:(void (^)(NSString *filePath))block {

    NSArray *types = @[@"png",@"jpeg",@"jpg",@"tiff"];
    
    if([types indexOfObject:[path pathExtension]] == NSNotFound) {
        ASLog(@"ImageAsset - Invalid extension %@", [path pathExtension]);
        return nil;
    }
    
    return [[[self class] alloc] initWithPath:path conversionComplete:block];
}


- (id) initWithPath: (NSString *) path conversionComplete:(void (^)(NSString *filePath))block {
    self = [super init];
    if (self) {
        self.path = path;


    }
    return self;
}


- (void)dealloc {
    image_ = nil;
    path_ = nil;
}


//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeObject:self.path forKey:@"path"];
    [encoder encodeObject:self.image forKey:@"image"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ((self = [super initWithCoder:decoder])) {
        self.path = [decoder decodeObjectForKey:@"path"];
        self.image = [decoder decodeObjectForKey:@"image"];
    }
    return self;
}

#pragma mark -

@end
