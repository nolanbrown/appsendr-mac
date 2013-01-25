//
//  ASObject.m
//  AppSendr
//
//  Created by Nolan Brown on 1/31/12.
//  Copyright (c) 2012AppSendr. See LICENSE.txt for Licensing Infomation
//

#import "ASObject.h"

@implementation ASObject


- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)aCoder;
{

}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    if ((self = [super init])) {
        
    }
    return self;
}

- (BOOL) destroyAtPath: (NSString *) path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    return YES;	
}


- (BOOL) writeToDisk: (NSString *) path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    ASLog(@"Writing %@ to %@",self,path);
    return [NSKeyedArchiver archiveRootObject:self toFile:path];	
}

+ (id) loadFromDisk: (NSString *) path {
    return (ASObject *)[NSKeyedUnarchiver unarchiveObjectWithFile:path];


}

@end
